#include "server.hpp"
#include "listener.hpp"
#include "client_session.hpp"
#include "router.hpp"
#include <iostream>

Server::Server(asio::io_context& io, uint16_t port)
    : io_(io) {
    if (!app_config_.load()) {
        throw std::runtime_error("Failed to load app config");
    }
    router_ = std::make_unique<Router>(*this);
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