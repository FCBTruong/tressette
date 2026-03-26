#pragma once

#include <cstdint>
#include <string>

#include "net/cmd.hpp"

struct PacketReceivedEvent {
    uint64_t uid = 0;
    Cmd cmd_id = Cmd::PING_PONG;
    std::string payload;
};

struct UserLoggedInEvent {
    uint64_t uid = 0;
};

struct UserLoginSettledEvent {
    uint64_t uid = 0;
};

struct UserDisconnectedEvent {
    uint64_t uid = 0;
};
