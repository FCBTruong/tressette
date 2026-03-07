#pragma once

#include <boost/asio.hpp>
#include <cstdint>

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

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