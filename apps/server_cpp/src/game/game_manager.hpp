// game_manager.hpp
#pragma once

#include <cstdint>
#include <chrono>
#include "net/game_client.hpp"
#include "game/users_info_mgr.hpp"
#include <nlohmann/json.hpp>

class GameManager {
public:
    GameManager(IGameClient& net, UsersInfoMgr& users_info_mgr);
    ~GameManager() = default;

    void on_login_success(uint64_t uid);
    void on_receive_packet(uint64_t uid, Cmd cmd_id, const std::string& payload);

private:
    void handle_log_out(uint64_t uid);
    void load_config();
private:
    IGameClient& net_;
    UsersInfoMgr& users_info_mgr_;
    nlohmann::json config_;
};