#include "tressette_bot.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <limits>
#include <optional>
#include <unordered_map>
#include <utility>
#include <vector>

namespace tressette_ai {
namespace {

constexpr int kNoCard = -1;
constexpr int kLastTrickBonus = 3;

struct SearchResult {
    int eval = 0;
    int bot_score = 0;
    int player_score = 0;
    int best_move = kNoCard;
};

struct StateKey {
    Leader leader = Leader::Bot;
    int bot_score = 0;
    int player_score = 0;
    int leading_card = kNoCard;
    int depth = 0;

    std::vector<int> bot_cards;
    std::vector<int> player_cards;
    std::vector<int> next_bot_cards;
    std::vector<int> next_player_cards;

    bool operator==(const StateKey& other) const {
        return leader == other.leader &&
               bot_score == other.bot_score &&
               player_score == other.player_score &&
               leading_card == other.leading_card &&
               depth == other.depth &&
               bot_cards == other.bot_cards &&
               player_cards == other.player_cards &&
               next_bot_cards == other.next_bot_cards &&
               next_player_cards == other.next_player_cards;
    }
};

struct StateKeyHash {
    static void hash_combine(std::size_t& seed, std::size_t value) {
        seed ^= value + 0x9e3779b97f4a7c15ULL + (seed << 6) + (seed >> 2);
    }

    static std::size_t hash_vector(const std::vector<int>& values) {
        std::size_t seed = values.size();
        for (int value : values) {
            hash_combine(seed, std::hash<int>{}(value));
        }
        return seed;
    }

    std::size_t operator()(const StateKey& key) const {
        std::size_t seed = 0;
        hash_combine(seed, std::hash<int>{}(static_cast<int>(key.leader)));
        hash_combine(seed, std::hash<int>{}(key.bot_score));
        hash_combine(seed, std::hash<int>{}(key.player_score));
        hash_combine(seed, std::hash<int>{}(key.leading_card));
        hash_combine(seed, std::hash<int>{}(key.depth));
        hash_combine(seed, hash_vector(key.bot_cards));
        hash_combine(seed, hash_vector(key.player_cards));
        hash_combine(seed, hash_vector(key.next_bot_cards));
        hash_combine(seed, hash_vector(key.next_player_cards));
        return seed;
    }
};

using Memo = std::unordered_map<StateKey, SearchResult, StateKeyHash>;

inline bool rules_valid(const Rules& rules) {
    return rules.get_suit != nullptr &&
           rules.get_score != nullptr &&
           rules.get_stronger_card != nullptr;
}

inline int evaluate_heuristic(
    int bot_score,
    int player_score,
    const std::vector<int>& bot_cards,
    const std::vector<int>& player_cards,
    const Rules& rules
) {
    int bot_potential = 0;
    int player_potential = 0;

    for (int card : bot_cards) {
        bot_potential += rules.get_score(card);
    }
    for (int card : player_cards) {
        player_potential += rules.get_score(card);
    }

    return (bot_score - player_score) + (bot_potential - player_potential) / 2;
}

inline std::vector<int> build_valid_responses(
    const std::vector<int>& cards,
    int lead_suit,
    const Rules& rules
) {
    std::vector<int> valid;
    valid.reserve(cards.size());

    for (int card : cards) {
        if (rules.get_suit(card) == lead_suit) {
            valid.push_back(card);
        }
    }

    if (valid.empty()) {
        return cards;
    }

    return valid;
}

inline std::vector<int> remove_one_card(const std::vector<int>& cards, int target_card) {
    std::vector<int> result;
    result.reserve(cards.size() > 0 ? cards.size() - 1 : 0);

    bool removed = false;
    for (int card : cards) {
        if (!removed && card == target_card) {
            removed = true;
            continue;
        }
        result.push_back(card);
    }

    return result;
}

inline void draw_next_cards(
    std::vector<int>& bot_cards,
    std::vector<int>& player_cards,
    std::vector<int>& next_bot_cards,
    std::vector<int>& next_player_cards
) {
    if (next_bot_cards.empty() || next_player_cards.empty()) {
        return;
    }

    bot_cards.push_back(next_bot_cards.front());
    player_cards.push_back(next_player_cards.front());

    next_bot_cards.erase(next_bot_cards.begin());
    next_player_cards.erase(next_player_cards.begin());
}

SearchResult solve_state(
    Leader leading_player,
    int bot_score,
    int player_score,
    const std::vector<int>& bot_cards,
    const std::vector<int>& player_cards,
    const std::vector<int>& next_bot_cards,
    const std::vector<int>& next_player_cards,
    std::optional<int> leading_card,
    int depth,
    int point_to_win,
    const Rules& rules,
    Memo& memo
) {
    if (bot_cards.empty() && player_cards.empty()) {
        return SearchResult{
            bot_score - player_score,
            bot_score,
            player_score,
            kNoCard
        };
    }

    if (depth <= 0) {
        return SearchResult{
            evaluate_heuristic(bot_score, player_score, bot_cards, player_cards, rules),
            bot_score,
            player_score,
            kNoCard
        };
    }

    StateKey key;
    key.leader = leading_player;
    key.bot_score = bot_score;
    key.player_score = player_score;
    key.leading_card = leading_card.value_or(kNoCard);
    key.depth = depth;
    key.bot_cards = bot_cards;
    key.player_cards = player_cards;
    key.next_bot_cards = next_bot_cards;
    key.next_player_cards = next_player_cards;

    const auto memo_it = memo.find(key);
    if (memo_it != memo.end()) {
        return memo_it->second;
    }

    // Bot leads.
    if (leading_player == Leader::Bot) {
        SearchResult best;
        best.eval = std::numeric_limits<int>::min();
        best.bot_score = std::numeric_limits<int>::min();
        best.player_score = std::numeric_limits<int>::max();
        best.best_move = kNoCard;

        for (int bot_card : bot_cards) {
            const int lead_suit = rules.get_suit(bot_card);
            const std::vector<int> valid_player_responses =
                build_valid_responses(player_cards, lead_suit, rules);

            // Player minimizes bot result.
            SearchResult worst_for_bot_move;
            worst_for_bot_move.eval = std::numeric_limits<int>::max();
            worst_for_bot_move.bot_score = std::numeric_limits<int>::max();
            worst_for_bot_move.player_score = std::numeric_limits<int>::min();
            worst_for_bot_move.best_move = kNoCard;

            for (int player_card : valid_player_responses) {
                const int trick_points = rules.get_score(bot_card) + rules.get_score(player_card);

                int next_bot_score = bot_score;
                int next_player_score = player_score;
                Leader next_leader = Leader::Bot;

                if (rules.get_suit(bot_card) == rules.get_suit(player_card)) {
                    const int winner = rules.get_stronger_card(bot_card, player_card);
                    if (winner == bot_card) {
                        next_bot_score += trick_points;
                        next_leader = Leader::Bot;
                    } else {
                        next_player_score += trick_points;
                        next_leader = Leader::Player;
                    }
                } else {
                    next_bot_score += trick_points;
                    next_leader = Leader::Bot;
                }

                SearchResult child;

                if (next_bot_score >= point_to_win || next_player_score >= point_to_win) {
                    if (bot_cards.size() == 1 && player_cards.size() == 1) {
                        if (next_leader == Leader::Bot) {
                            next_bot_score += kLastTrickBonus;
                        } else {
                            next_player_score += kLastTrickBonus;
                        }
                    }

                    child = SearchResult{
                        next_bot_score - next_player_score,
                        next_bot_score,
                        next_player_score,
                        kNoCard
                    };
                } else {
                    std::vector<int> new_bot_cards = remove_one_card(bot_cards, bot_card);
                    std::vector<int> new_player_cards = remove_one_card(player_cards, player_card);
                    std::vector<int> new_next_bot_cards = next_bot_cards;
                    std::vector<int> new_next_player_cards = next_player_cards;

                    draw_next_cards(
                        new_bot_cards,
                        new_player_cards,
                        new_next_bot_cards,
                        new_next_player_cards
                    );

                    child = solve_state(
                        next_leader,
                        next_bot_score,
                        next_player_score,
                        new_bot_cards,
                        new_player_cards,
                        new_next_bot_cards,
                        new_next_player_cards,
                        std::nullopt,
                        depth - 1,
                        point_to_win,
                        rules,
                        memo
                    );
                }

                if (child.eval < worst_for_bot_move.eval) {
                    worst_for_bot_move = child;
                }
            }

            if (worst_for_bot_move.eval > best.eval) {
                best = worst_for_bot_move;
                best.best_move = bot_card;
            }
        }

        memo.emplace(std::move(key), best);
        return best;
    }

    // Player leads, but the leading card is not chosen yet.
    if (!leading_card.has_value()) {
        SearchResult worst;
        worst.eval = std::numeric_limits<int>::max();
        worst.bot_score = std::numeric_limits<int>::max();
        worst.player_score = std::numeric_limits<int>::min();
        worst.best_move = kNoCard;

        for (int player_lead_card : player_cards) {
            SearchResult child = solve_state(
                Leader::Player,
                bot_score,
                player_score,
                bot_cards,
                player_cards,
                next_bot_cards,
                next_player_cards,
                player_lead_card,
                depth,
                point_to_win,
                rules,
                memo
            );

            if (child.eval < worst.eval) {
                worst = child;
            }
        }

        memo.emplace(std::move(key), worst);
        return worst;
    }

    // Player leads with a known card.
    const int player_card = *leading_card;
    const int lead_suit = rules.get_suit(player_card);
    const std::vector<int> valid_bot_responses =
        build_valid_responses(bot_cards, lead_suit, rules);

    SearchResult best;
    best.eval = std::numeric_limits<int>::min();
    best.bot_score = std::numeric_limits<int>::min();
    best.player_score = std::numeric_limits<int>::max();
    best.best_move = kNoCard;

    for (int bot_card : valid_bot_responses) {
        const int trick_points = rules.get_score(player_card) + rules.get_score(bot_card);

        int next_bot_score = bot_score;
        int next_player_score = player_score;
        Leader next_leader = Leader::Player;

        if (rules.get_suit(player_card) == rules.get_suit(bot_card)) {
            const int winner = rules.get_stronger_card(player_card, bot_card);
            if (winner == bot_card) {
                next_bot_score += trick_points;
                next_leader = Leader::Bot;
            } else {
                next_player_score += trick_points;
                next_leader = Leader::Player;
            }
        } else {
            next_player_score += trick_points;
            next_leader = Leader::Player;
        }

        SearchResult child;

        if (next_bot_score >= point_to_win || next_player_score >= point_to_win) {
            if (bot_cards.size() == 1 && player_cards.size() == 1) {
                if (next_leader == Leader::Bot) {
                    next_bot_score += kLastTrickBonus;
                } else {
                    next_player_score += kLastTrickBonus;
                }
            }

            child = SearchResult{
                next_bot_score - next_player_score,
                next_bot_score,
                next_player_score,
                kNoCard
            };
        } else {
            std::vector<int> new_bot_cards = remove_one_card(bot_cards, bot_card);
            std::vector<int> new_player_cards = remove_one_card(player_cards, player_card);
            std::vector<int> new_next_bot_cards = next_bot_cards;
            std::vector<int> new_next_player_cards = next_player_cards;

            draw_next_cards(
                new_bot_cards,
                new_player_cards,
                new_next_bot_cards,
                new_next_player_cards
            );

            child = solve_state(
                next_leader,
                next_bot_score,
                next_player_score,
                new_bot_cards,
                new_player_cards,
                new_next_bot_cards,
                new_next_player_cards,
                std::nullopt,
                depth - 1,
                point_to_win,
                rules,
                memo
            );
        }

        if (child.eval > best.eval) {
            best = child;
            best.best_move = bot_card;
        }
    }

    memo.emplace(std::move(key), best);
    return best;
}

} // namespace

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
    std::optional<int> leading_card,
    int max_depth
) {
    if (!rules_valid(rules)) {
        return kNoCard;
    }

    Memo memo;
    memo.reserve(1024);

    const SearchResult result = solve_state(
        leading_player,
        bot_score,
        player_score,
        bot_cards,
        player_cards,
        next_bot_cards,
        next_player_cards,
        leading_card,
        max_depth,
        point_to_win,
        rules,
        memo
    );

    return result.best_move;
}

} // namespace tressette_ai