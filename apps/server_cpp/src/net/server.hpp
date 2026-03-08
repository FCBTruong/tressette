#pragma once

#include <boost/asio.hpp>
#include <cstdint>
#include <memory>

#include "config/app_config.hpp"
#include "auth/auth_service.hpp"
#include "net/session_registry.hpp"
#include "net/game_client.hpp"   
#include "game/match/match_registry.hpp"
#include "game/users_info_mgr.hpp"

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

class ClientSession;
class Listener;
class Router;

class Server {
public:
    Server(asio::io_context& io, uint16_t port);
    ~Server();

    void start();

    void on_new_connection(tcp::socket socket);
    void remove_session(uint64_t session_id);

    Router& router();

    SessionRegistry& session_registry() { return session_registry_; }
    AuthService& auth_service() { return auth_service_; }
    const AppConfig& app_config() const { return app_config_; }
    MatchRegistry& match_registry() { return match_registry_; }
    IGameClient& game_client() { return game_client_; }
    UsersInfoMgr& users_info_mgr() { return users_info_mgr_; }

private:
    asio::io_context& io_;
    std::unique_ptr<Listener> listener_;
    std::unique_ptr<Router> router_;

    // order matters (constructed in this order)
    SessionRegistry session_registry_;
    GameClient game_client_;
    MatchRegistry match_registry_;
    UsersInfoMgr users_info_mgr_;

    AppConfig app_config_;
    AuthService auth_service_;
    uint64_t next_session_id_ = 1;
};