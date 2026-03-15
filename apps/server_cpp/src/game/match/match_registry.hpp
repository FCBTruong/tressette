#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>
#include "match.hpp"
#include "net/game_client.hpp"
#include "game/users_info_mgr.hpp"
#include "net/session_registry.hpp"

class MatchRegistry {
public:
    explicit MatchRegistry(IGameClient& net, UsersInfoMgr& users_info_mgr, SessionRegistry& session_registry);

    void start();
    void stop();
    void update();

    std::shared_ptr<IMatch> create_match(
        int game_mode,
        int player_mode,
        bool is_private = false,
        int point_mode = 11
    );

    std::shared_ptr<IMatch> get_match(int64_t match_id) const;
    std::shared_ptr<IMatch> get_match_of_user(uint64_t uid) const;

    bool is_user_in_match(uint64_t uid) const;
    void on_received_packet(uint64_t uid, Cmd cmd_id, const std::string& payload);
    bool user_join_match(const std::shared_ptr<IMatch>& match, uint64_t uid);
    void user_disconnect(uint64_t uid);
    void user_ready(uint64_t uid);
    void receive_request_table_list(uint64_t uid);
    void receive_user_join_match(uint64_t uid, const std::string& payload);
    void receive_quick_play(uint64_t uid, const std::string& payload);
    void received_create_table(uint64_t uid, const std::string& payload);
    void on_user_login(uint64_t uid);

private:
    std::shared_ptr<IMatch> find_a_suitable_match_quickplay() const;
    std::vector<std::shared_ptr<IMatch>> prioritize_matches(uint64_t uid) const;

    void handle_quick_play(uint64_t uid);
    void handle_user_join_by_match_id(uint64_t uid, int64_t match_id);
    void send_response_join_table(uint64_t uid, JoinMatchErrors status);
    void on_user_removed_from_match(uint64_t uid, int64_t match_id);
    void flush_pending_destroy_matches();
    void request_destroy_match(int64_t match_id);
    void destroy_match_now(int64_t match_id);

private:
    int64_t next_match_id_ = 1000;
    std::unordered_map<int64_t, std::shared_ptr<IMatch>> matches_;
    std::unordered_map<uint64_t, int64_t> user_match_ids_;
    bool running_ = false;
    IGameClient& net_;
    UsersInfoMgr& users_info_mgr_;
    SessionRegistry& session_registry_;
    std::unordered_set<int64_t> pending_destroy_match_ids_;
};