#pragma once

#include <cstdint>
#include <functional>
#include <set>
#include <string>
#include <vector>
#include <numeric>

#include <google/protobuf/message.h>

#include "packet.pb.h"
#include "net/cmd.hpp"
#include "net/game_client.hpp"
#include "game/users_info_mgr.hpp"
#include "match_player.hpp"
#include "net/session_registry.hpp"
#include "game/match/match.hpp"

enum class PlayCardErrors {
    Success = 0,
    NotInGame = 1,
    NotYourTurn = 2,
    InvalidCard = 3,
    NotFoundCard = 4,
    InvalidSuit = 5,
    NotInHand = 6
};

enum class LeaveTressetteErrors {
    Success = 0,
    NotInTressette = 1,
    TressetteStarted = 2
};

const std::unordered_map<int, int> TRESSETTE_CARD_STRONGS = {
    {2, 100},
    {1, 99},
    {0, 98},
    {9, 97},
    {8, 96},
    {7, 95},
    {6, 94},
    {5, 93},
    {4, 92},
    {3, 91}
};

const std::unordered_map<int, int> TRESSETTE_CARD_VALUES = {
    {0, 3}, {1, 3}, {2, 3}, {3, 3},       // Aces
    {4, 1}, {5, 1}, {6, 1}, {7, 1},       // 2s
    {8, 1}, {9, 1}, {10, 1}, {11, 1},     // 3s
    {12, 0}, {13, 0}, {14, 0}, {15, 0},   // 4s
    {16, 0}, {17, 0}, {18, 0}, {19, 0},   // 5s
    {20, 0}, {21, 0}, {22, 0}, {23, 0},   // 6s
    {24, 0}, {25, 0}, {26, 0}, {27, 0},   // 7s
    {28, 1}, {29, 1}, {30, 1}, {31, 1},   // Jacks
    {32, 1}, {33, 1}, {34, 1}, {35, 1},   // Queens
    {36, 1}, {37, 1}, {38, 1}, {39, 1}    // Kings
};

constexpr int PLAYER_SOLO_MODE = 2;
constexpr int PLAYER_DUO_MODE = 4;
constexpr int TRESSETTE_MODE = 0;
constexpr int SETTE_MEZZO_MODE = 1;

constexpr int SERVER_SCORE_ONE_POINT = 3;
constexpr int SCORE_WIN_GAME_ELEVEN = 11 * SERVER_SCORE_ONE_POINT;
constexpr int SCORE_WIN_GAME_TWENTY_ONE = 21 * SERVER_SCORE_ONE_POINT;

constexpr int BOT_MODEL_STUPID = 0;
constexpr int BOT_MODEL_MEDIUM = 1;
constexpr int BOT_MODEL_ADVANCE = 2;
constexpr int BOT_MODEL_SUPER = 3;
constexpr int BOT_MODEL_SUPER_V2 = 4;

constexpr int TEAM_ID_1 = 0;
constexpr int TEAM_ID_2 = 1;

constexpr int TIME_MATCH_MAXIMUM = 60 * 60 * 1000; // 1 hour
constexpr int TIME_PREPARE_START = 3000; // 3 seconds to prepare start game after room is full
constexpr uint64_t PLAYER_EMPTY_UID = 0;

const std::vector<int> TRESSETTE_CARDS = [] {
    std::vector<int> v(40);
    std::iota(v.begin(), v.end(), 0);
    return v;
}();

struct TressetteReward {
    int item_id = 0;
    int value = 0;
    int duration = 0;
};

class Tressette : public IMatch {
public:
    using UserRemovedCallback = std::function<void(uint64_t, int64_t)>;

public:
    Tressette(int64_t match_id, int player_mode, int point_mode,
          IGameClient& net, UsersInfoMgr& users_info_mgr, SessionRegistry& session_registry);

    ~Tressette() = default;

// IMatch interface
    void set_user_removed_callback(UserRemovedCallback cb) override {
        on_user_removed_ = std::move(cb);
    }
    void on_received_packet(uint64_t uid, int cmd_id, const std::string& payload) override;
    JoinMatchErrors try_join(uint64_t user_id, bool is_bot = false) override;
    void user_reconnect(uint64_t uid) override;
    void loop() override;
    bool check_room_full() const override;
    int game_mode() const override { return game_mode_; }
    int64_t match_id() const override { return match_id_; }
    int player_mode() const override { return player_mode_; }
    MatchState state() const override { return state_; }
    bool is_public() const override { return is_public_; }
    const std::vector<MatchPlayer>& players() const override { return players_; }
    const std::set<uint64_t>& viewers() const override { return viewers_; }
    void user_disconnect(uint64_t uid) override;
    void set_is_pending_destroyed(bool v) override;
    int get_num_players() const override;
    bool should_destroy() const override;

// Setters and getters
    bool has_user(uint64_t uid) const;
    bool is_player(uint64_t uid) const;
    bool is_viewer(uint64_t uid) const;
    bool set_public(bool v) {
        is_public_ = v;
        return true;
    }
    int hand_suit() const { return hand_suit_; }
    int point_mode() const { return point_mode_; }
	const std::vector<int>& cards_compare() const { return cards_compare_; }
    int point_to_win() const {
        return point_to_win_;
    }
    void test_fill_bots();
    bool is_pending_destroyed() const { return is_pending_destroyed_; }
    bool has_online_user() const;
    void handle_play_card(uint64_t uid, int card_id, bool is_auto = false);
private:
    void send_game_info_to_user(uint64_t uid);
    bool check_has_real_players() const;
    void user_ready(uint64_t uid);
    void broadcast_pkg(Cmd cmd, const google::protobuf::Message& msg,
                    const std::vector<uint64_t>& exclude_uids = {});
    void broadcast_chat_emoticon(uint64_t uid, int emoticon);
    void broadcast_chat_message(uint64_t uid, const std::string& message);
    void user_return_to_table(uint64_t uid);
    void user_leave(uint64_t uid, int reason = 0);
    void handle_register_leave_game(uint64_t uid, const packet::RegisterLeaveGame& req);
    int find_player_index(uint64_t uid) const;
    void notify_user_removed(uint64_t uid);
    void end_game();
    void start_game();
    void prepare_start_game();
    void deal_cards();
    void handle_new_hand();
    void send_card_play_response(uint64_t uid, PlayCardErrors status);
    bool check_done_hand() const;
    void end_hand(packet::PlayCard& play_card_pkg);
    int get_win_card_in_hand() const;
    int get_win_score_in_hand() const;
    void handle_end_round();
    void handle_draw_card();
    void handle_new_round();
    bool check_end_game();
    void update_users_staying_endgame();
    void handle_game_action_napoli(int64_t uid);
	void handle_viewer_enter_match(uint64_t uid, int seat_idx);
    std::vector<std::vector<int>> find_napoli(const std::vector<int>& hand);
    void check_gen_bot();
    void schedule_gen_bot();

private:
    IGameClient& net_;
    UsersInfoMgr& users_info_mgr_;
    UserRemovedCallback on_user_removed_;
    SessionRegistry& session_registry_;

    int64_t last_time_changed_player_sec_ = 0;
    int time_gen_bot_interval_sec_ = 0;
    int64_t match_id_ = 0;
    int player_mode_ = PLAYER_SOLO_MODE;
    int point_mode_ = 21;
    int game_mode_ = TRESSETTE_MODE;
    int current_turn_idx_ = 0;
    int current_hand_ = 0;
    int current_round_ = 0;
    std::vector<int> cards_compare_;
    std::vector<int> cards_;
    std::vector<int> team_scores_;
    int hand_suit_ = 0;
    int cur_round_ = 0;
    int hand_in_round_ = 0;
    int point_to_win_ = 0;
    int64_t time_start_ = -1;
    int last_won_uid_;
    int win_team_id_ = -1;
    int bot_start_uid_ = BOT_START_UID;

    MatchState state_ = MatchState::Waiting;
    bool is_public_ = true;
    bool is_in_game_ = false;
	bool is_pending_destroyed_ = false;

    std::string unique_match_id_;
    std::string unique_game_id_;

    std::vector<MatchPlayer> players_;
    std::set<uint64_t> viewers_;
    std::set<uint64_t> register_leave_uids_;
    DelayedTaskQueue delayed_tasks_;
    std::unordered_map<uint64_t, int> napoli_claimed_status_; // uid -> napoli claimed status (0: not claimed, 1: claimed 1/3, 2: claimed 2/3)
};