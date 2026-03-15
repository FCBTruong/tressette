// match_player.cpp
#include "match_player.hpp"
#include "game/match/modes/tressette.hpp"
#include "game/match/ai/tressette_bot.hpp"
#include "game/game_constants.hpp"

void MatchPlayer::on_turn() {
    is_on_turn_ = true;
    if (is_bot) {
		int delayed = rand() % 2 + 1; // Random delay between 1 and 2 seconds
        time_auto_play_ms_ = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()
        ).count() + delayed * 1000;
    }
    else {
            time_auto_play_severe_ms_ = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()
            ).count() + GameConstants::TIME_AUTO_PLAY_SEVERE * 1000;
 
            time_auto_play_ms_ = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()
            ).count() + GameConstants::TIME_AUTO_PLAY * 1000;
    }

    if (GameConstants::DEV_MODE && is_bot) {
        send_cheat_view_card();
	}
}

void MatchPlayer::reset_new_game() {
    points = 0;
    score_last_trick = 0;
    is_in_game = true;
    bet = 0;
	is_auto_ = false;
	is_on_turn_ = false;
	cards.clear();
}

void MatchPlayer::auto_play() {
    is_auto_ = true;

    // Get current suit
    int hand_suit = match_->hand_suit();

    if (cards.empty()) {
        return;
    }

    int card_id = cards[0];
    // Try to find card in same suit
    for (const auto& c : cards) {
        if (c % 4 == hand_suit) {
            card_id = c;
            break;
        }
    }
    match_->handle_play_card(uid, card_id, true);
}

void MatchPlayer::random_chat() {
}

void MatchPlayer::reset_game() {
    cards.clear();
    points = 0;
    score_last_trick = 0;
    is_in_game = false;
    bet = 0;
}

bool MatchPlayer::play_card(int card_id) {
    auto it = std::find(cards.begin(), cards.end(), card_id);
    if (it == cards.end()) {
        return false;
    }
    cards.erase(it);
    is_on_turn_ = false;
    return true;
}

bool MatchPlayer::has_suit(int suit) const {
    for (const auto& c : cards) {
        if (c % 4 == suit) {
            return true;
        }
    }
    return false;
}

void MatchPlayer::bot_play_card() {
    if (cards.empty()) {
        return;
    }

    const int hand_suit = match_->hand_suit();

    std::vector<int> bot_cards = cards;
    std::vector<int> player_cards;
    std::vector<int> next_bot_cards;
    std::vector<int> next_player_cards;

    int player_score = 0;

    for (const auto& p : match_->players()) {
        if (p.uid == uid || p.team_id == team_id || p.is_empty()) {
            continue;
        }

        player_cards = p.cards;
        player_score = p.points;
        break; // 1v1 for now
    }

    tressette_ai::Rules rules;
    rules.get_suit = [](int card) {
        return card % 4;
        };
    rules.get_score = [](int card) {
        return TRESSETTE_CARD_VALUES.at(card);
        };

    rules.get_stronger_card = [](int card1, int card2) {
        const int rank1 = card1 / 4;
        const int rank2 = card2 / 4;

        return (TRESSETTE_CARD_STRONGS.at(rank1) >= TRESSETTE_CARD_STRONGS.at(rank2))
            ? card1
            : card2;
        };

    int card_to_play = -1;

    if (hand_suit == -1) {
        card_to_play = tressette_ai::find_optimal_card(
            tressette_ai::Leader::Bot,
            points,
            player_score,
            bot_cards,
            player_cards,
            next_bot_cards,
            next_player_cards,
            rules,
            match_->point_to_win(),
            std::nullopt,
            depth_strategy_
        );
    }
    else {
        int leading_card = -1;
        const auto& compared = match_->cards_compare();
        for (int c : compared) {
            if (c != -1) {
                leading_card = c;
                break;
            }
        }

        card_to_play = tressette_ai::find_optimal_card(
            tressette_ai::Leader::Player,
            points,
            player_score,
            bot_cards,
            player_cards,
            next_bot_cards,
            next_player_cards,
            rules,
            match_->point_mode(),
            leading_card == -1 ? std::nullopt : std::optional<int>(leading_card),
            depth_strategy_
        );
    }

    if (card_to_play == -1) {
        card_to_play = cards[0];
    }

    match_->handle_play_card(uid, card_to_play);
}

void MatchPlayer::loop() {
    if (!is_on_turn_) {
        return;
    }
    int64_t now_ts_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()
    ).count();

    if (is_bot) {
        if (now_ts_ms >= time_auto_play_ms_) {
            bot_play_card();
        }
    }
    else {
        if (is_auto_ && now_ts_ms >= time_auto_play_severe_ms_) {
            auto_play();
		}
        else if (now_ts_ms >= time_auto_play_ms_) {
            auto_play();
		}
    }
}

void MatchPlayer::send_cheat_view_card() {
    packet::CheatViewCardBot pkg;
    for (const auto& c : cards) {
        pkg.add_cards(c);
    }
    // match_->broadcast_pkg(Cmd::CHEAT_VIEW_CARD_BOT, pkg);
}