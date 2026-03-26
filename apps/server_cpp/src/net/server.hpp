#pragma once

#include <boost/asio.hpp>
#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "config/app_config.hpp"
#include "core/signal_bus.hpp"
#include "auth/auth_service.hpp"
#include "db/postgres_client.hpp"
#include "notify/telegram_notifier.hpp"
#include "net/session_registry.hpp"
#include "net/game_client.hpp"   
#include "game/match/match_registry.hpp"
#include "game/users_info_mgr.hpp"
#include "game/game_manager.hpp"

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

class ClientSession;
class Listener;
class Router;

class Server {
public:
    Server(asio::io_context& io);
    ~Server();

    void start();

    void on_new_connection(tcp::socket socket);
    void remove_session(uint64_t session_id);

    Router& router();
    asio::any_io_executor main_executor() { return io_.get_executor(); }
    SignalBus& signal_bus() { return signal_bus_; }

    SessionRegistry& session_registry() { return session_registry_; }
    AuthService& auth_service() { return auth_service_; }
    const AppConfig& app_config() const { return app_config_; }
    MatchRegistry& match_registry() { return match_registry_; }
    IGameClient& game_client() { return game_client_; }
    UsersInfoMgr& users_info_mgr() { return users_info_mgr_; }
    GameManager& game_manager() { return game_manager_; }
    PostgresClient& db() { return *db_; }
    void execute_db_async(
        std::string sql,
        std::vector<DbValue> params,
        std::function<void(DbResult)> on_success,
        std::function<void(std::string)> on_error = {});

private:
    void wire_signal_handlers();
    void schedule_update();
    void notify_startup();
private:
    asio::io_context& io_;
    std::unique_ptr<Listener> listener_;
    std::unique_ptr<Router> router_;

    // order matters (constructed in this order)
    SessionRegistry session_registry_;
    GameClient game_client_;
    UsersInfoMgr users_info_mgr_;
    MatchRegistry match_registry_;
    GameManager game_manager_;

    AppConfig app_config_;
    SignalBus signal_bus_;
    AuthService auth_service_;
    std::unique_ptr<PostgresClient> db_;
    asio::thread_pool db_executor_{1};
    std::unique_ptr<TelegramNotifier> telegram_notifier_;
    uint64_t next_session_id_ = 1;
    std::unique_ptr<asio::steady_timer> update_timer_;
};
