#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>
#include "match.hpp"
#include "net/game_client.hpp"
#include "game/users_info_mgr.hpp"

class MatchRegistry {
public:
    explicit MatchRegistry(IGameClient& net, UsersInfoMgr& users_info_mgr);

    void start();
    void stop();
    void update();

    std::shared_ptr<Match> create_match(
        int game_mode,
        int player_mode,
        bool is_private = false,
        int point_mode = 11
    );

    std::shared_ptr<Match> get_match(int64_t match_id) const;
    std::shared_ptr<Match> get_match_of_user(uint64_t uid) const;

    bool is_user_in_match(uint64_t uid) const;

    void on_received_packet(uint64_t uid, Cmd cmd_id, const std::string& payload);
    void destroy_match(int64_t match_id);

    bool user_join_match(const std::shared_ptr<Match>& match, uint64_t uid);
    void user_disconnect(uint64_t uid);

    void user_play_card(uint64_t uid, const std::string& payload);
    void user_ready(uint64_t uid);
    void receive_user_return_to_table(uint64_t uid);
    void receive_game_action_napoli(uint64_t uid, const std::string& payload);

    void receive_request_table_list(uint64_t uid);
    void receive_user_join_match(uint64_t uid, const std::string& payload);
    void receive_quick_play(uint64_t uid, const std::string& payload);
    void received_create_table(uint64_t uid, const std::string& payload);
    void handle_register_leave_match(uint64_t uid, const std::string& payload);
    void view_game(uint64_t uid, const std::string& payload);
    void on_user_login(uint64_t uid);

private:
    std::shared_ptr<Match> find_a_suitable_match_quickplay() const;
    std::vector<std::shared_ptr<Match>> prioritize_matches(uint64_t uid) const;

    void handle_quick_play(uint64_t uid);
    void handle_user_join_by_match_id(uint64_t uid, int64_t match_id);
    void send_response_join_table(uint64_t uid, JoinMatchErrors status);

    void on_user_removed_from_match(uint64_t uid, int64_t match_id);

private:
    int64_t next_match_id_ = 1000;
    std::unordered_map<int64_t, std::shared_ptr<Match>> matches_;
    std::unordered_map<uint64_t, int64_t> user_match_ids_;
    bool running_ = false;
    IGameClient& net_;
    UsersInfoMgr& users_info_mgr_;
};