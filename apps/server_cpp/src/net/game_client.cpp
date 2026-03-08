#include "net/game_client.hpp"

#include "net/session_registry.hpp"
#include "client_session.hpp"

GameClient::GameClient(SessionRegistry& reg) : reg_(reg) {}

bool GameClient::send_packet(uint64_t uid, int cmd_id, const google::protobuf::Message& msg) {
    auto session = reg_.find_by_uid(uid);
    if (!session) return false;
    return session->send_packet(cmd_id, msg);
}