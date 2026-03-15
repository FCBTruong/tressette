// match_player.hpp
#pragma once

#include <cstdint>
#include <string>
#include <vector>
#include "game/game_constants.hpp"

class Tressette;

class MatchPlayer {
public:
    explicit MatchPlayer(Tressette* match) : match_(match) {}
    ~MatchPlayer() = default;

    void on_turn();
    void auto_play();
    void random_chat();
    void reset_game();
    bool has_suit(int suit) const;
	void reset_new_game();

    bool is_empty() const noexcept {
        return uid == GameConstants::EMPTY_PLAYER_UID;
    }

    void clear() {
        *this = MatchPlayer{match_};
    }

    bool play_card(int card_id);
    void bot_play_card();
    void loop();
    bool is_on_turn() const { return is_on_turn_; }
    bool is_auto() const { return is_auto_; }
    void set_auto(bool v) { is_auto_ = v; }
    void set_depth_strategy(int depth) {
        depth_strategy_ = depth;
    }
private:
    void send_cheat_view_card();

private:
    bool is_auto_ = false;
public:
    uint64_t uid = GameConstants::EMPTY_PLAYER_UID;
    std::string name;
    std::string avatar;
    int64_t gold = 0;
    std::vector<int> cards;
    int points = 0;
    int score_last_trick = 0;
    int team_id = -1;
    bool is_bot = false;
    bool is_in_game = false;
    int64_t bet = 0;
    int avatar_frame = 0;

private:
    Tressette* match_ = nullptr;
	bool is_on_turn_ = false;
	int64_t time_auto_play_ms_ = 0;
	int64_t time_auto_play_severe_ms_ = 0;
    int depth_strategy_ = 1; // for bot: 1-easy, 2-medium, 3-hard
};