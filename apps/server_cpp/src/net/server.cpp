#include "server.hpp"
#include "listener.hpp"
#include "client_session.hpp"
#include "router.hpp"
#include <iostream>

Server::Server(asio::io_context& io, uint16_t port)
    : io_(io) {
    router_ = std::make_unique<Router>();
    listener_ = std::make_unique<Listener>(io_, port, *this);
}

Server::~Server() = default;

void Server::start() {
    listener_->start();
}

void Server::on_new_connection(tcp::socket socket) {
    const uint64_t session_id = next_session_id_++;

    auto session = std::make_shared<ClientSession>(
        std::move(socket),
        session_id,
        *this
    );

    sessions_[session_id] = session;

    std::cout << "New client connected, session_id=" << session_id << '\n';

    session->start();
}

void Server::remove_session(uint64_t session_id) {
    sessions_.erase(session_id);
    std::cout << "Session removed, session_id=" << session_id << '\n';
}

Router& Server::router() {
    return *router_;
}