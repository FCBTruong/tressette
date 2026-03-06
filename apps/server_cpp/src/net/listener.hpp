#pragma once

#include <asio.hpp>
#include <cstdint>

using asio::ip::tcp;

class Server;

class Listener {
public:
    Listener(asio::io_context& io, uint16_t port, Server& server);
    void start();

private:
    void do_accept();

private:
    tcp::acceptor acceptor_;
    Server& server_;
};