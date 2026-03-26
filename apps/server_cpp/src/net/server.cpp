#include "server.hpp"
#include "listener.hpp"
#include "client_session.hpp"
#include "router.hpp"

#include <exception>
#include <iostream>
#include <boost/asio/steady_timer.hpp>

#include "core/app_events.hpp"

Server::Server(asio::io_context& io)
    : io_(io),
      session_registry_(),
      game_client_(session_registry_),
      users_info_mgr_(),
      match_registry_(game_client_, users_info_mgr_, session_registry_), // inject net sender into match system
      game_manager_(game_client_, users_info_mgr_)
{
    if (!app_config_.load()) {
        throw std::runtime_error("Failed to load app config");
    }

    db_ = std::make_unique<PostgresClient>(app_config_.db_url());
    if (!db_->connect()) {
        std::cout << "Database base is not active yet: " << db_->last_error() << '\n';
    } else {
        std::cout << "Database base ready for repositories: " << db_->connection_info().summary() << '\n';
    }

    telegram_notifier_ = std::make_unique<TelegramNotifier>(
        app_config_.telegram_bot_token(),
        app_config_.telegram_chat_id(),
        app_config_.telegram_skip_tls_verify()
    );

    uint64_t port = app_config_.port();
    router_ = std::make_unique<Router>(*this);
    wire_signal_handlers();
    listener_ = std::make_unique<Listener>(io_, port, *this);
    update_timer_ = std::make_unique<asio::steady_timer>(io_);

    std::cout << "Server initialized, listening on port " << port << '\n';
}

Server::~Server() = default;

void Server::start() {
    listener_->start();
    match_registry_.start();
    schedule_update();
    notify_startup();
}

void Server::on_new_connection(tcp::socket socket) {
    const uint64_t session_id = next_session_id_++;

    auto session = std::make_shared<ClientSession>(
        std::move(socket),
        session_id,
        *this
    );

    session_registry_.add_session(session);

    std::cout << "New client connected, session_id=" << session_id << '\n';

    session->start();
}

void Server::remove_session(uint64_t session_id) {
    ClientSession* session = session_registry_.find_by_session_id(session_id).get();
    if (session) {
        int64_t uid = session->uid().value_or(0);
        if (uid) {
            signal_bus_.publish(UserDisconnectedEvent{static_cast<uint64_t>(uid)});
        }
    }
    session_registry_.remove_session(session_id);
    std::cout << "Session removed, session_id=" << session_id << '\n';
}

Router& Server::router() {
    return *router_;
}

void Server::wire_signal_handlers() {
    signal_bus_.subscribe<PacketReceivedEvent>(
        [this](const PacketReceivedEvent& event) {
            match_registry_.on_received_packet(event.uid, event.cmd_id, event.payload);
        });

    signal_bus_.subscribe<PacketReceivedEvent>(
        [this](const PacketReceivedEvent& event) {
            users_info_mgr_.on_receive_packet(event.uid, event.cmd_id, event.payload);
        });

    signal_bus_.subscribe<PacketReceivedEvent>(
        [this](const PacketReceivedEvent& event) {
            game_manager_.on_receive_packet(event.uid, event.cmd_id, event.payload);
        });

    signal_bus_.subscribe<UserLoggedInEvent>(
        [this](const UserLoggedInEvent& event) {
            game_manager_.on_login_success(event.uid);

            auto timer = std::make_shared<asio::steady_timer>(io_);
            timer->expires_after(std::chrono::seconds(2));
            timer->async_wait([this, timer, uid = event.uid](const boost::system::error_code& ec) {
                if (!ec) {
                    signal_bus_.publish(UserLoginSettledEvent{uid});
                }
            });
        });

    signal_bus_.subscribe<UserLoginSettledEvent>(
        [this](const UserLoginSettledEvent& event) {
            match_registry_.on_user_login(event.uid);
        });

    signal_bus_.subscribe<UserDisconnectedEvent>(
        [this](const UserDisconnectedEvent& event) {
            match_registry_.user_disconnect(event.uid);
        });
}

void Server::schedule_update() {
    update_timer_->expires_after(std::chrono::milliseconds(500));
    update_timer_->async_wait([this](const boost::system::error_code& ec) {
        if (ec) {
            return;
        }

        match_registry_.update();
        schedule_update();
    });
}

void Server::notify_startup() {
    if (app_config_.environment_mode() == AppConfig::EnvironmentMode::kDevelopment) {
        std::cout << "Running in development mode, skipping Telegram notification\n";
        return;
    }

    if (!telegram_notifier_ || !telegram_notifier_->enabled()) {
        return;
    }

    std::string error_message;
    const std::string message =
        "Tressette server started.\n"
        "Port: " + std::to_string(app_config_.port());

    if (!telegram_notifier_->send_message(message, &error_message)) {
        std::cout << "Telegram startup notification failed: " << error_message << '\n';
    } else {
        std::cout << "Telegram startup notification sent\n";
    }

    if (app_config_.telegram_skip_tls_verify()) {
        std::cout << "Warning: Telegram notifier is running with TLS verification disabled\n";
    }
}

void Server::execute_db_async(
    std::string sql,
    std::vector<DbValue> params,
    std::function<void(DbResult)> on_success,
    std::function<void(std::string)> on_error) {
    asio::post(
        db_executor_,
        [this,
         sql = std::move(sql),
         params = std::move(params),
         on_success = std::move(on_success),
         on_error = std::move(on_error)]() mutable {
            try {
                DbResult result = db_->execute(sql, params);
                asio::post(
                    io_,
                    [result = std::move(result), on_success = std::move(on_success)]() mutable {
                        if (on_success) {
                            on_success(std::move(result));
                        }
                    });
            } catch (const std::exception& e) {
                std::string error_message = e.what();
                asio::post(
                    io_,
                    [error_message = std::move(error_message), on_error = std::move(on_error)]() mutable {
                        if (on_error) {
                            on_error(std::move(error_message));
                        }
                    });
            }
        });
}
