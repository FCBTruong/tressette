#pragma once

#include <memory>

#include "packet.pb.h"

class ClientSession;

class Router {
public:
    void handle(const std::shared_ptr<ClientSession>& session, const Packet& packet);

private:
    void handle_ping(const std::shared_ptr<ClientSession>& session, const Packet& packet);
    void handle_login(const std::shared_ptr<ClientSession>& session, const Packet& packet);
};