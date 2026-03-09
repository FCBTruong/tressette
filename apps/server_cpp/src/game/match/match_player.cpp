// match_player.cpp
#include "match_player.hpp"
#include "match.hpp"

void MatchPlayer::on_turn() {
}

void MatchPlayer::auto_play() {
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
    match_->handle_play_card(uid, card_id);
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