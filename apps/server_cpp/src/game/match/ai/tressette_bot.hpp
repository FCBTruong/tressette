#pragma once

#include <cstdint>
#include <optional>
#include <vector>

namespace tressette_ai {

enum class Leader : std::uint8_t {
    Bot = 0,
    Player = 1
};

struct Rules {
    int (*get_suit)(int) = nullptr;
    int (*get_score)(int) = nullptr;
    int (*get_stronger_card)(int, int) = nullptr;
};

int find_optimal_card(
    Leader leading_player,
    int bot_score,
    int player_score,
    const std::vector<int>& bot_cards,
    const std::vector<int>& player_cards,
    const std::vector<int>& next_bot_cards,
    const std::vector<int>& next_player_cards,
    const Rules& rules,
    int point_to_win,
    std::optional<int> leading_card = std::nullopt,
    int max_depth = 2
);

} // namespace tressette_ai