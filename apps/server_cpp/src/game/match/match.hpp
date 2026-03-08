#pragma once

#include <cstdint>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include <google/protobuf/message.h>

#include "net/cmd.hpp"          // Cmd enum
#include "net/game_client.hpp"  // IGameClient
#include "game/users_info_mgr.hpp"  // UsersInfoMgr

class MatchPlayer;

enum class MatchState {
    Waiting = 0,
    PreparingStart = 1,
    Playing = 2,
    Ending = 3,
    Ended = 4,
    Betting = 5
};

enum class PlayCardErrors {
    Success = 0,
    NotInGame = 1,
    NotYourTurn = 2,
    InvalidCard = 3,
    NotFoundCard = 4,
    InvalidSuit = 5,
    NotInHand = 6
};

enum class LeaveMatchErrors {
    Success = 0,
    NotInMatch = 1,
    MatchStarted = 2
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

struct MatchReward {
    int item_id = 0;
    int value = 0;
    int duration = 0;
};

class Match {
public:
    Match(int64_t match_id, int player_mode, int point_mode,
          IGameClient& net, UsersInfoMgr& users_info_mgr);

    virtual ~Match() = default;

    // network entry
    virtual void on_received_packet(uint64_t uid, int cmd_id, const std::string& payload);

    // common sends
    virtual void broadcast_pkg(Cmd cmd, const google::protobuf::Message& msg,
                               const std::vector<uint64_t>& exclude_uids = {});
    virtual void send_game_info_to_user(uint64_t uid);

    // common match actions (override in mode if needed)
    virtual void user_join(uint64_t user_id, bool is_bot = false);
    virtual void user_leave(uint64_t uid, int reason = 0);
    virtual void user_reconnect(uint64_t uid);
    virtual void loop();

    virtual void broadcast_chat_emoticon(uint64_t uid, int emoticon);
    virtual void broadcast_chat_message(uint64_t uid, const std::string& message);

    virtual void user_return_to_table(uint64_t uid);
    virtual void user_ready(uint64_t uid);

    virtual bool check_room_full() const;
    virtual void user_stop_view(uint64_t uid, bool should_send_back_to_user = true);
    virtual void user_view_game(uint64_t uid);
    virtual bool check_has_real_players() const;

    // getters
    virtual int game_mode() const { return game_mode_; }
    virtual int64_t match_id() const { return match_id_; }
    virtual int player_mode() const { return player_mode_; }
    virtual MatchState state() const { return state_; }
    virtual bool is_public() const { return is_public_; }
    virtual int get_num_players() const;
    virtual const std::vector<std::shared_ptr<MatchPlayer>>& players() const { return players_; }
    virtual bool set_public(bool v) { is_public_ = v; return true; }

protected:
    IGameClient& net_;
    UsersInfoMgr& users_info_mgr_;

    int64_t match_id_ = 0;
    int player_mode_ = PLAYER_SOLO_MODE;
    int point_mode_ = 21;
    int game_mode_ = TRESSETTE_MODE;
    int current_turn_ = 0;
    std::vector<int> cards_compare_;
    std::vector<int> cards_;
    int hand_suit_ = 0;
    int cur_round_ = 0;
    int hand_in_round_ = 0;
    int point_to_win_ = 0;

    MatchState state_ = MatchState::Waiting;
    bool is_public_ = true;

    std::string unique_match_id_;
    std::string unique_game_id_;

    std::vector<std::shared_ptr<MatchPlayer>> players_;  // REQUIRED
    std::set<uint64_t> viewers_;
    std::vector<uint64_t> users_auto_play_;
    std::set<uint64_t> register_leave_uids_;
};