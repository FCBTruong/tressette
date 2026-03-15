#pragma once

#include <cstdint>
#include <functional>
#include <set>
#include <string>
#include <vector>
#include "delayed_task_queue.hpp"

class MatchPlayer;

enum class JoinMatchErrors {
    Success = 0,
    MatchStarted = 1,
    FullRoom = 2,
    NotEnoughGold = 3,
    AlreadyInMatch = 4,
    MatchNotFound = 5
};

enum class MatchState {
    Waiting = 0,
    PreparingStart = 1,
    Playing = 2,
    Ending = 3,
    Ended = 4
};

class IMatch {
public:
    using UserRemovedCallback = std::function<void(uint64_t, int64_t)>;

    virtual ~IMatch() = default;

    virtual void set_user_removed_callback(UserRemovedCallback cb) = 0;
    virtual void loop() = 0;
    virtual JoinMatchErrors try_join(uint64_t user_id, bool is_bot = false) = 0;
    virtual void user_disconnect(uint64_t uid) = 0;
    virtual void user_reconnect(uint64_t uid) = 0;
    virtual void on_received_packet(uint64_t uid, int cmd_id, const std::string& payload) = 0;
    virtual int64_t match_id() const = 0;
    virtual bool is_pending_destroyed() const = 0;
    virtual bool is_public() const = 0;
    virtual const std::vector<MatchPlayer>& players() const = 0;
    virtual const std::set<uint64_t>& viewers() const = 0;
    virtual void set_is_pending_destroyed(bool v) = 0;
    virtual MatchState state() const = 0;
    virtual int player_mode() const = 0;
    virtual bool check_room_full() const = 0;
    virtual int get_num_players() const = 0;
    virtual int game_mode() const = 0;
    virtual bool should_destroy() const = 0;
};