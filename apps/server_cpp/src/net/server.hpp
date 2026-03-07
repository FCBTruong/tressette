#pragma once

#include <boost/asio.hpp>
#include <cstdint>
#include <memory>
#include <unordered_map>
#include "session_registry.hpp"
#include "auth/auth_service.hpp"
#include "config/app_config.hpp"

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
private:
    asio::io_context& io_;
    std::unique_ptr<Listener> listener_;
    std::unique_ptr<Router> router_;
    SessionRegistry session_registry_;
    AppConfig app_config_;
    AuthService auth_service_;
    uint64_t next_session_id_ = 1;
};