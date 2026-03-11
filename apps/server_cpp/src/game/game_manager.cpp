// game_manager.cpp
#include "game_manager.hpp"
#include <fstream>

GameManager::GameManager(IGameClient& net, UsersInfoMgr& users_info_mgr)
    : net_(net), users_info_mgr_(users_info_mgr) {
    load_config();
}

void GameManager::load_config() {
    std::ifstream file("config/tressette_game_config.json");
    if (!file.is_open()) {
        throw std::runtime_error("Failed to open config/tressette_game_config.json");
    }

    file >> config_;
}

void GameManager::on_login_success(uint64_t uid) {
    // send general info
    std::ifstream file("config/tressette_game_config.json");
    if (!file.is_open()) {
        throw std::runtime_error("Failed to open config/tressette_game_config.json");
    }

    nlohmann::json config;
    file >> config;

    packet::GeneralInfo general_pkg;

    const int64_t timestamp_now = std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::system_clock::now().time_since_epoch()
    ).count();

    general_pkg.set_time_thinking_in_turn(config.value("time_thinking_in_turn", 0));
    general_pkg.set_timestamp(timestamp_now);
    general_pkg.set_fee_mode_no_bet(config.value("fee_mode_no_bet", 0));
    general_pkg.set_enable_ads(true);

    if (config.contains("exp_levels") && config["exp_levels"].is_array()) {
        for (const auto& exp_level : config["exp_levels"]) {
            general_pkg.add_exp_levels(exp_level.get<int>());
        }
    }

    if (config.contains("level_rewards") && config["level_rewards"].is_array()) {
        for (const auto& reward : config["level_rewards"]) {
            auto* level_reward = general_pkg.add_level_rewards();
            level_reward->set_level(reward.value("level", 0));
            level_reward->set_gold(reward.value("gold", 0));

            if (reward.contains("items") && reward["items"].is_array()) {
                for (const auto& item : reward["items"]) {
                    auto* reward_item = level_reward->add_items();
                    reward_item->set_item_id(item.value("item_id", 0));
                    reward_item->set_duration(item.value("duration", 0));
                }
            }
        }
    }

    net_.send_packet(uid, Cmd::GENERAL_INFO, general_pkg);

    // send user info
    packet::UserInfo info;
    info.set_uid(static_cast<int64_t>(uid));

    const auto user_info = users_info_mgr_.get_or_create(uid);
    info.set_name(user_info.name);
    info.set_avatar(user_info.avatar);
    info.set_avatar_third_party(user_info.avatar_third_party);
    info.set_avatar_frame(user_info.avatar_frame);
    info.set_add_for_user_support(false);
    
    net_.send_packet(uid, Cmd::USER_INFO, info);
}

void GameManager::on_receive_packet(uint64_t uid, Cmd cmd_id, const std::string& payload) {
    switch (cmd_id) {
        case Cmd::LOG_OUT:
            handle_log_out(uid);
            break;
        default:
            break;
    }
}

void GameManager::handle_log_out(uint64_t uid) {
    packet::Logout pkg;
    net_.send_packet(uid, Cmd::LOG_OUT, pkg);
}