// net/router.hpp
#pragma once

#include <memory>

#include "packet.pb.h"

class ClientSession;
class Server;

class Router {
public:
    explicit Router(Server& server);

    void handle(const std::shared_ptr<ClientSession>& session, const packet::Packet& packet);

private:
    void handle_ping(const std::shared_ptr<ClientSession>& session, const packet::Packet& packet);
    void handle_login(const std::shared_ptr<ClientSession>& session, const packet::Packet& packet);
    void send_auth_error(const std::shared_ptr<ClientSession>& session, int cmd_id);

private:
    Server& server_;
};