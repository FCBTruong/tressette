#include "listener.hpp"
#include "server.hpp"
#include <iostream>

Listener::Listener(asio::io_context& io, uint16_t port, Server& server)
    : acceptor_(io, tcp::endpoint(tcp::v4(), port)),
      server_(server) {}

void Listener::start() {
    do_accept();
}

void Listener::do_accept() {
    acceptor_.async_accept(
        [this](std::error_code ec, tcp::socket socket) {
            if (!ec) {
                server_.on_new_connection(std::move(socket));
            } else {
                std::cerr << "Accept error: " << ec.message() << '\n';
            }

            do_accept();
        }
    );
}