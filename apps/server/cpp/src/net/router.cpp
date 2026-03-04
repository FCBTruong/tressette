#include "router.hpp"
#include "client_session.hpp"
#include <string>
#include <iostream>
#include "net/cmd.hpp"
#include "packet.pb.h"

static std::vector<uint8_t> to_bytes(const std::string& s) {
    return std::vector<uint8_t>(s.begin(), s.end());
}

void Router::handle(const std::shared_ptr<ClientSession>& session, const Packet& packet) {
    std::cout << "Received packet from session " << session->session_id()
              << ": cmd_id=" << packet.cmd_id()
              << ", token=" << packet.token()
              << ", payload_size=" << packet.payload().size() << '\n';
              
    switch (packet.cmd_id()) {
        case Cmd::PING:
            handle_ping(session, packet);
            break;
        case Cmd::LOGIN:
            handle_login(session, packet);
            break;
        default:
            std::cerr << "Unknown opcode from session " << session->session_id() << '\n';
            break;
    }
}

void Router::handle_ping(const std::shared_ptr<ClientSession>& session, const Packet& /*packet*/) {
    Packet reply;
    reply.set_cmd_id(Cmd::PONG);
    session->send(reply);
}

void Router::handle_login(const std::shared_ptr<ClientSession>& session, const Packet& packet) {
    Login login;
    if (!login.ParseFromString(packet.payload())) {
        std::cerr << "Invalid Login payload from session " << session->session_id() << '\n';
        return;
    }

    std::cout << "Session " << session->session_id()
              << " login token=" << login.token()
              << ", platform=" << login.platform()
              << ", device_model=" << login.device_model()
              << '\n';

    LoginResponse login_response;
    login_response.set_uid(123);
    login_response.set_token("server_token");
    login_response.set_error(0);

    std::string response_payload;
    if (!login_response.SerializeToString(&response_payload)) {
        std::cerr << "Failed to serialize LoginResponse\n";
        return;
    }

    Packet reply;
    reply.set_token(packet.token());
    reply.set_cmd_id(Cmd::LOGIN);
    reply.set_payload(response_payload);

    session->send(reply);
}
