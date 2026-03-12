// net/router.cpp
#include "router.hpp"

#include <iostream>
#include <memory>
#include <string>

#include "auth/auth_service.hpp"
#include "client_session.hpp"
#include "cmd.hpp"
#include "server.hpp"
#include "game/game_constants.hpp"

Router::Router(Server& server)
    : server_(server) {}

void Router::handle(const std::shared_ptr<ClientSession>& session, const packet::Packet& packet) {
    if (!server_.auth_service().is_authorized(*session, packet)) {
        send_auth_error(session, packet.cmd_id());
        return;
    }

    switch (packet.cmd_id()) {
        case Cmd::PING_PONG:
            handle_ping(session, packet);
            break;
        case Cmd::LOGIN:
            handle_login(session, packet);
            break;
        default:
            Cmd cmd_id = static_cast<Cmd>(packet.cmd_id());
            int uid = session->uid().value_or(0);

            // Dispatch on received packet event to listeners
            server_.match_registry().on_received_packet(uid, cmd_id, packet.payload());
            server_.users_info_mgr().on_receive_packet(uid, cmd_id, packet.payload());
            server_.game_manager().on_receive_packet(uid, cmd_id, packet.payload());
            break;
    }
}

void Router::handle_ping(const std::shared_ptr<ClientSession>& session, const packet::Packet& /*packet*/) {
    packet::Packet reply;
    reply.set_cmd_id(Cmd::PING_PONG);
    session->send(reply);
}

void Router::handle_login(const std::shared_ptr<ClientSession>& session, const packet::Packet& packet) {
    packet::Login login;
    if (!login.ParseFromString(packet.payload())) {
        std::cerr << "Invalid Login payload from session " << session->session_id() << '\n';
        return;
    }

    auto result = server_.auth_service().login(
        login.token(),
        login.platform(),
        login.device_model());

    auto user_info = server_.users_info_mgr().get_or_create(result.uid);
    server_.users_info_mgr().set_name(result.uid, "User_" + std::to_string(result.uid));
    int avt_client_id = login.avatar_id();

    // validate avatar is in AVATAR_IDS
    if (std::find(GameConstants::AVATAR_IDS.begin(), GameConstants::AVATAR_IDS.end(), avt_client_id) != GameConstants::AVATAR_IDS.end()) {
        server_.users_info_mgr().set_avatar(result.uid, std::to_string(avt_client_id));
    } else {
        server_.users_info_mgr().set_avatar(result.uid, "1"); // default avatar
    }

    int avt_frame_client_id = login.avatar_frame_id();
    if (std::find(GameConstants::AVATAR_FRAME_IDS.begin(), GameConstants::AVATAR_FRAME_IDS.end(), avt_frame_client_id) != GameConstants::AVATAR_FRAME_IDS.end()) {
        server_.users_info_mgr().set_avatar_frame(result.uid, avt_frame_client_id);
    } else {
        server_.users_info_mgr().set_avatar_frame(result.uid, GameConstants::AVATAR_FRAME_DEFAULT); // default avatar frame
    }

    packet::LoginResponse login_response;
    login_response.set_error(result.error);

    if (result.success) {
        login_response.set_uid(result.uid);
        login_response.set_token(result.session_token);
    
        session->bind_uid(result.uid);
        session->set_session_token(result.session_token);
        server_.session_registry().bind_uid(result.uid, session->session_id());
    }

    std::string response_payload;
    if (!login_response.SerializeToString(&response_payload)) {
        std::cerr << "Failed to serialize LoginResponse\n";
        return;
    }

    packet::Packet reply;
    reply.set_cmd_id(Cmd::LOGIN);
    reply.set_token(result.success ? result.session_token : "");
    reply.set_payload(response_payload);

    session->send(reply);

    server_.game_manager().on_login_success(result.uid);

    std::thread([this, uid = result.uid]() {
        std::this_thread::sleep_for(std::chrono::seconds(2));
        server_.match_registry().on_user_login(uid);
    }).detach();
}

void Router::send_auth_error(const std::shared_ptr<ClientSession>& session, int cmd_id) {
    packet::LoginResponse response;
    response.set_error(401);

    std::string payload;
    if (!response.SerializeToString(&payload)) {
        return;
    }

    packet::Packet reply;
    reply.set_cmd_id(cmd_id);
    reply.set_payload(payload);

    session->send(reply);
}