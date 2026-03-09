// users_info_mgr.cpp
#include "users_info_mgr.hpp"

#include <algorithm>
#include <cctype>
#include <iostream>

UserInfo UsersInfoMgr::get_or_create(uint64_t uid) {
    std::lock_guard<std::mutex> lk(mu_);
    auto it = users_.find(uid);
    if (it != users_.end()) return it->second;

    UserInfo u;
    u.uid = uid;
    users_.emplace(uid, u);
    return u;
}

void UsersInfoMgr::upsert(const UserInfo& info) {
    std::lock_guard<std::mutex> lk(mu_);
    users_[info.uid] = info;
}

void UsersInfoMgr::remove(uint64_t uid) {
    std::lock_guard<std::mutex> lk(mu_);
    users_.erase(uid);
}

bool UsersInfoMgr::check_user_vip(uint64_t uid, int64_t now_unix_sec) const {
    std::lock_guard<std::mutex> lk(mu_);
    auto it = users_.find(uid);
    if (it == users_.end()) return false;
    return it->second.time_show_ads > now_unix_sec;
}

void UsersInfoMgr::on_receive_packet(uint64_t uid, Cmd cmd_id, const std::string& payload) {
    switch (cmd_id) {
        case Cmd::CHANGE_AVATAR:
            handle_change_avatar(uid, payload);
            return;
        case Cmd::CHANGE_USER_NAME:
            handle_change_user_name(uid, payload);
            return;
        case Cmd::CHEAT_GOLD_USER:
            handle_cheat_gold_user(uid, payload);
            return;
        case Cmd::CHEAT_EXP_USER:
            handle_cheat_exp_user(uid, payload);
            return;
        default:
            return;
    }
}

void UsersInfoMgr::handle_change_avatar(uint64_t uid, const std::string& payload) {
    packet::ChangeAvatar req;
    if (!req.ParseFromString(payload)) return;

    const int avatar_id = req.avatar_id();

    std::lock_guard<std::mutex> lk(mu_);
    auto& user = users_[uid];
    user.uid = uid;

    // Python logic: avatar_id == -1 => third_party avatar must exist
    if (avatar_id == -1) {
        if (user.avatar_third_party.empty()) {
            return;
        }
        user.avatar = user.avatar_third_party;
        return;
    }

    // If you need AVATAR_IDS validation, do it here.
    user.avatar = std::to_string(avatar_id);
}

void UsersInfoMgr::handle_cheat_gold_user(uint64_t uid, const std::string& payload) {
    packet::CheatGoldUser req;
    if (!req.ParseFromString(payload)) return;

    const int64_t add_gold = req.gold();

    std::lock_guard<std::mutex> lk(mu_);
    auto& user = users_[uid];
    user.uid = uid;
    user.gold += add_gold;
}

void UsersInfoMgr::handle_cheat_exp_user(uint64_t uid, const std::string& payload) {
    packet::CheatExpUser req;
    if (!req.ParseFromString(payload)) return;

    const int add_exp = req.exp();

    std::lock_guard<std::mutex> lk(mu_);
    auto& user = users_[uid];
    user.uid = uid;
    user.exp += add_exp;
}

std::string UsersInfoMgr::trim(std::string s) {
    auto not_space = [](unsigned char ch) { return !std::isspace(ch); };
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), not_space));
    s.erase(std::find_if(s.rbegin(), s.rend(), not_space).base(), s.end());
    return s;
}

void UsersInfoMgr::handle_change_user_name(uint64_t uid, const std::string& payload) {
    packet::ChangeUserName req;
    if (!req.ParseFromString(payload)) return;

    std::string new_name = trim(req.name());

    // Python validation: 1..25
    if (new_name.size() < 1 || new_name.size() > 25) {
        return;
    }

    std::lock_guard<std::mutex> lk(mu_);
    auto& user = users_[uid];
    user.uid = uid;

    // No inventory / rename-card logic per your request (cache only)
    user.name = std::move(new_name);
    user.num_change_name += 1;
}