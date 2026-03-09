#include "server.hpp"
#include "listener.hpp"
#include "client_session.hpp"
#include "router.hpp"
#include <iostream>
#include <boost/asio/steady_timer.hpp>

Server::Server(asio::io_context& io, uint16_t port)
    : io_(io),
      session_registry_(),
      game_client_(session_registry_),
      users_info_mgr_(),
      match_registry_(game_client_, users_info_mgr_), // inject net sender into match system
      game_manager_(game_client_, users_info_mgr_)
{
    if (!app_config_.load()) {
        throw std::runtime_error("Failed to load app config");
    }
    router_ = std::make_unique<Router>(*this);
    listener_ = std::make_unique<Listener>(io_, port, *this);
    update_timer_ = std::make_unique<asio::steady_timer>(io_);
}

Server::~Server() = default;

void Server::start() {
    listener_->start();
    match_registry_.start();
    schedule_update();
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
    session_registry_.remove_session(session_id);
    std::cout << "Session removed, session_id=" << session_id << '\n';
}

Router& Server::router() {
    return *router_;
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