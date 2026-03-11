// users_info_mgr.hpp
#pragma once

#include <cstdint>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>

#include "net/cmd.hpp"
#include "packet.pb.h"

// Minimal cached user model (extend fields as needed)
struct UserInfo {
    uint64_t uid = 0;
    std::string name = "tressette player";
    int64_t gold = 0;
    int level = 1;

    std::string avatar;              // e.g. "12" or url
    std::string avatar_third_party;  // url
    int avatar_frame = 0;

    int win_count = 0;
    int game_count = 0;
    int exp = 0;

    int num_payments = 0;
    int num_claimed_ads = 0;

    int64_t time_show_ads = 0;   // unix seconds; > now => VIP in your logic
    int64_t time_ads_reward = 0;
    int64_t last_time_online = 0;

    int num_change_name = 0;
};

constexpr uint64_t BOT_START_UID = 1000000;
class UsersInfoMgr {
public:
    UsersInfoMgr();

    // Get cached user; create if missing (default values).
    UserInfo get_or_create(uint64_t uid);

    // Update full user object in cache (overwrite).
    void upsert(const UserInfo& info);

    // Remove cache entry.
    void remove(uint64_t uid);

    // Read packet from client and update cache.
    void on_receive_packet(uint64_t uid, Cmd cmd_id, const std::string& payload);

    // Same VIP logic as python: time_show_ads > now.
    bool check_user_vip(uint64_t uid, int64_t now_unix_sec) const;

    int request_bot(); // return bot uid
    void release_bot(int bot_uid);
private:
    void handle_change_avatar(uint64_t uid, const std::string& payload);
    void handle_change_user_name(uint64_t uid, const std::string& payload);
    // Helpers
    static std::string trim(std::string s);

private:
    mutable std::mutex mu_;
    std::unordered_map<uint64_t, UserInfo> users_;
    std::vector<int> available_uids_;
    std::unordered_set<int> in_use_uids_;
};