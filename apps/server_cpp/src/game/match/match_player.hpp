// match_player.hpp
#pragma once

#include <cstdint>
#include <string>
#include <vector>
#include "game/game_constants.hpp"
class Match;

class MatchPlayer {
public:
    explicit MatchPlayer(Match* match) : match_(match) {}
    ~MatchPlayer() = default;

    void on_turn();
    void auto_play();
    void random_chat();
    void reset_game();
    bool has_suit(int suit) const;

    bool is_empty() const noexcept {
        return uid == GameConstants::EMPTY_PLAYER_UID;
    }

    void clear() {
        *this = MatchPlayer{match_};
    }

    bool play_card(int card_id);
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
    Match* match_ = nullptr;
};