// net/game_client.hpp
#pragma once
#include <cstdint>
#include <google/protobuf/message.h>

class SessionRegistry;

class IGameClient {
public:
    virtual ~IGameClient() = default;
    virtual bool send_packet(uint64_t uid, int cmd_id, const google::protobuf::Message& msg) = 0;
};

class GameClient final : public IGameClient {
public:
    explicit GameClient(SessionRegistry& reg);
    bool send_packet(uint64_t uid, int cmd_id,
                     const google::protobuf::Message& msg) override;

private:
    SessionRegistry& reg_;
};