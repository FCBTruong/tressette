#pragma once
#include <cstdint>
#include <string>
#include <vector>

struct MatchPlayer {
    uint64_t uid = 0;
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

    MatchPlayer() = default;
    virtual ~MatchPlayer() = default;

    virtual void on_turn();
    virtual void auto_play();
    virtual void random_chat();

    void reset_game();
};
