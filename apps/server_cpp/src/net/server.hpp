#pragma once

#include <asio.hpp>
#include <memory>
#include <unordered_map>
#include <cstdint>

using asio::ip::tcp;

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

private:
    asio::io_context& io_;
    std::unique_ptr<Listener> listener_;
    std::unique_ptr<Router> router_;

    uint64_t next_session_id_ = 1;
    std::unordered_map<uint64_t, std::shared_ptr<ClientSession>> sessions_;
};