#include "match.hpp"

#include <cstdint>
#include <iostream>
#include <string>
#include <unordered_set>
#include <vector>
#include <chrono>
#include <random>
#include "packet.pb.h"

Match::Match(int64_t match_id, int player_mode, int point_mode,
             IGameClient& net, UsersInfoMgr& users_info_mgr)
    : net_(net),
      users_info_mgr_(users_info_mgr),
      match_id_(match_id),
      player_mode_(player_mode),
      point_mode_(point_mode) 
{
    for (int i = 0; i < player_mode_; ++i) {
        players_.emplace_back(this);
        players_.back().team_id = (i % 2 == 0) ? TEAM_ID_1 : TEAM_ID_2;
    }

    cards_compare_.reserve(static_cast<std::size_t>(player_mode_));
    // assign default -1 value to cards_compare_ for all players
    for (int i = 0; i < player_mode_; ++i) {
        cards_compare_.push_back(-1);
    }
    point_to_win_ = point_mode_ * 3;
}

void Match::on_received_packet(uint64_t uid, int cmd_id, const std::string& payload) {
    if (is_pending_destroyed_) {
        return;
    }

    switch (cmd_id) {
        case Cmd::USER_READY_MATCH:
            user_ready(uid);
            return;

        case Cmd::USER_RETURN_TO_TABLE:
            user_return_to_table(uid);
            return;

        case Cmd::NEW_INGAME_CHAT_MESSAGE: {
            packet::InGameChatMessage req;
            if (!req.ParseFromString(payload)) {
                return;
            }
            broadcast_chat_message(uid, req.chat_message());
            return;
        }

        case Cmd::CHAT_EMOTICON: {
            packet::InGameChatEmoticon req;
            if (!req.ParseFromString(payload)) {
                return;
            }
            broadcast_chat_emoticon(uid, req.emoticon());
            return;
        }

        case Cmd::REGISTER_LEAVE_GAME: 
        {
            packet::RegisterLeaveGame req;
            if (!req.ParseFromString(payload)) {
                return;
            }
            handle_register_leave_game(uid, req);
            return;
        }
        case Cmd::PLAY_CARD: {
            packet::PlayCard req;
            if (!req.ParseFromString(payload)) {
                return;
            }
            handle_play_card(uid, req.card_id());
            break;
        }
        case Cmd::GAME_ACTION_NAPOLI: {
            packet::GameActionNapoli req;
            if (!req.ParseFromString(payload)) {
                return;
            }
            handle_game_action_napoli(uid);
			return;
        }
        case Cmd::VIWER_JOIN_MATCH: {
            packet::ViewerJoinMatch req;
            if (!req.ParseFromString(payload)) {
                return;
            }
            handle_viewer_enter_match(uid, req.seat_idx());
            break;
        }
        default:
            return;
    }
}

int Match::find_player_index(uint64_t uid) const {
    for (std::size_t i = 0; i < players_.size(); ++i) {
        if (!players_[i].is_empty() && players_[i].uid == uid) {
            return static_cast<int>(i);
        }
    }
    return -1;
}

bool Match::is_player(uint64_t uid) const {
    return find_player_index(uid) >= 0;
}

bool Match::is_viewer(uint64_t uid) const {
    return viewers_.count(uid) > 0;
}

bool Match::has_user(uint64_t uid) const {
    return is_player(uid) || is_viewer(uid);
}

void Match::notify_user_removed(uint64_t uid) {
    if (on_user_removed_) {
        on_user_removed_(uid, match_id_);
    }
}

void Match::broadcast_pkg(Cmd cmd, const google::protobuf::Message& msg,
                          const std::vector<uint64_t>& exclude_uids) 
{
    std::unordered_set<uint64_t> excluded(exclude_uids.begin(), exclude_uids.end());
    
    for (const auto& player : players_) {
        if (player.is_empty()) {
            std::cout << "Skipping empty player slot for broadcasting cmd " << static_cast<int>(cmd) << '\n';
            continue;
        }
        if (excluded.count(player.uid) > 0) {
            continue;
        }
        net_.send_packet(player.uid, cmd, msg);
    }

    for (uint64_t viewer_uid : viewers_) {
        if (excluded.count(viewer_uid) > 0) {
            continue;
        }
        net_.send_packet(viewer_uid, cmd, msg);
    }
}

JoinMatchErrors Match::try_join(uint64_t user_id, bool is_bot) {
    if (is_player(user_id)) {
        return JoinMatchErrors::AlreadyInMatch;
    }

    if (is_viewer(user_id)) {
        viewers_.erase(user_id);
    }

    int slot_idx = -1;
    for (std::size_t i = 0; i < players_.size(); ++i) {
        if (players_[i].is_empty()) {
            slot_idx = static_cast<int>(i);
            break;
        }
    }

    const auto info = users_info_mgr_.get_or_create(user_id);

    if (slot_idx >= 0) {
        auto& player = players_[static_cast<std::size_t>(slot_idx)];
        player.uid = user_id;
        player.is_bot = is_bot;
        player.name = info.name;
        player.avatar = info.avatar;
        player.avatar_frame = info.avatar_frame;
        player.gold = info.gold;

        if (is_bot) {
            player.set_depth_strategy(1 + rand() % 3);

            // should random avatar, avatar frame for it
            int random_avatar_id = GameConstants::AVATAR_IDS[rand() % GameConstants::AVATAR_IDS.size()];
            player.avatar = std::to_string(random_avatar_id);
            int random_avatar_frame_id = GameConstants::AVATAR_FRAME_IDS[rand() % GameConstants::AVATAR_FRAME_IDS.size()];
            player.avatar_frame = random_avatar_frame_id;
            player.name = "User_" + std::to_string(user_id);
        }
    
        int seat_server_id = slot_idx;
        packet::NewUserJoinMatch pkg;
        pkg.set_uid(static_cast<int64_t>(user_id));
        pkg.set_name(player.name);
        pkg.set_avatar(player.avatar);
        pkg.set_gold(player.gold);
        pkg.set_avatar_frame(player.avatar_frame);
        pkg.set_seat_server(seat_server_id);
		pkg.set_team_id(player.team_id);
        broadcast_pkg(Cmd::NEW_USER_JOIN_MATCH, pkg, {user_id});
    }
    else {
        viewers_.insert(user_id);
        packet::NewUserView pkg;
        pkg.set_uid(static_cast<int64_t>(user_id));
        const auto info = users_info_mgr_.get_or_create(user_id);
        pkg.set_avatar(info.avatar);
        pkg.set_name(info.name);
        pkg.set_avatar_frame(info.avatar_frame);
        broadcast_pkg(Cmd::NEW_USER_VIEW_GAME, pkg, {user_id});
    }

    send_game_info_to_user(user_id);

    schedule_gen_bot();
    return JoinMatchErrors::Success;
}

void Match::send_game_info_to_user(uint64_t uid) {
    std::cout << "Sending game info to user " << uid << " in match " << match_id() << '\n';

    packet::GameInfo game_info;
    game_info.set_match_id(match_id());
    game_info.set_game_mode(game_mode());
    game_info.set_player_mode(player_mode());
    game_info.set_game_state(static_cast<int>(state()));
    game_info.set_current_turn(current_turn_idx_);

    for (int c : cards_compare_) {
        game_info.add_cards_compare(c);
    }

    game_info.set_remain_cards(static_cast<int>(cards_.size()));
    game_info.set_hand_suit(hand_suit_);
    game_info.set_is_registered_leave(register_leave_uids_.count(uid) > 0);
    game_info.set_current_round(cur_round_);
    game_info.set_hand_in_round(hand_in_round_);
    game_info.set_point_to_win(point_to_win_);

    for (const auto& p : players_) {
        game_info.add_uids(static_cast<int64_t>(p.uid));
        game_info.add_user_golds(p.gold);
        game_info.add_user_names(p.name);
        game_info.add_user_points(p.points);
        game_info.add_team_ids(p.team_id);
        game_info.add_avatars(p.avatar);
        game_info.add_avatar_frames(p.avatar_frame);
        game_info.add_is_vips(false);

        if (p.uid == uid) {
            std::cout << "Adding cards for user " << uid << ": ";
            for (int card : p.cards) {
                game_info.add_my_cards(card);
            }
        }
    }

    for (uint64_t viewer_uid : viewers_) {
        const auto vinfo = users_info_mgr_.get_or_create(viewer_uid);
        game_info.add_viewer_uids(static_cast<int64_t>(viewer_uid));
        game_info.add_viewer_avatars(vinfo.avatar);
        game_info.add_viewer_names(vinfo.name);
        game_info.add_viewer_avatar_frames(vinfo.avatar_frame);
    }

    net_.send_packet(uid, Cmd::GAME_INFO, game_info);
}

void Match::user_leave(uint64_t uid, int reason) {
    bool removed = false;

    const int player_idx = find_player_index(uid);
    if (player_idx >= 0) {
        removed = true;
    }

    if (viewers_.count(uid) > 0) {
        removed = true;
    }

    if (!removed) {
        return;
    }

    packet::UserLeaveMatch pkg;
    pkg.set_uid(static_cast<int64_t>(uid));
    pkg.set_reason(reason);
    broadcast_pkg(Cmd::USER_LEAVE_MATCH, pkg);

    if (player_idx >= 0) {
		MatchPlayer& player = players_[static_cast<std::size_t>(player_idx)];
        if (player.is_bot) {
            users_info_mgr_.release_bot(uid);
        }
		player.clear();
    }
    viewers_.erase(uid);
    register_leave_uids_.erase(uid);

    if (state_ == MatchState::PreparingStart) {
        state_ = MatchState::Waiting;
    }

    schedule_gen_bot();
    notify_user_removed(uid);
}

void Match::user_reconnect(uint64_t uid) {
    if (!has_user(uid)) {
        return;
    }

    if (is_player(uid)) {
        const int player_idx = find_player_index(uid);
        if (player_idx >= 0) {
            players_[static_cast<std::size_t>(player_idx)].set_auto(false);
		}
    }

    send_game_info_to_user(uid);
}

void Match::loop() {
    if (is_pending_destroyed_) {
        return;
    }

    try {
        delayed_tasks_.run_due();   
        const int64_t now_ts = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()
        ).count();

        if (state_ == MatchState::Playing) {
            if (now_ts - time_start_ > TIME_MATCH_MAXIMUM) {
                end_game();
                return;
            }

			for (auto& player : players_) {
                if (!player.is_empty()) {
					player.loop();
                }
            }
        } else if (state_ == MatchState::PreparingStart) {
            if (time_start_ != -1 && now_ts > time_start_) {
                if (check_room_full()) {
                    start_game();
                } else {
                    state_ = MatchState::Waiting;
                    time_start_ = -1;
                }
            }
        } else if (state_ == MatchState::Waiting) {
            if (check_room_full()) {
                prepare_start_game();
            }
            else {
                check_gen_bot();
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "Match::loop exception: " << e.what() << '\n';
        throw;
    }
}

void Match::broadcast_chat_emoticon(uint64_t uid, int emoticon) {
    (void)uid;

    packet::InGameChatEmoticon pkg;
    pkg.set_emoticon(emoticon);
    pkg.set_uid(static_cast<int64_t>(uid));
    broadcast_pkg(Cmd::CHAT_EMOTICON, pkg);
}

void Match::broadcast_chat_message(uint64_t uid, const std::string& message) {
    (void)uid;

    packet::InGameChatMessage pkg;
    pkg.set_chat_message(message);
    pkg.set_uid(static_cast<int64_t>(uid));
    broadcast_pkg(Cmd::NEW_INGAME_CHAT_MESSAGE, pkg);
}

void Match::user_return_to_table(uint64_t uid) {
    if (!is_player(uid)) {
        return;
	}
	MatchPlayer& player = players_[static_cast<std::size_t>(find_player_index(uid))];
    if (player.is_auto()) {
        player.set_auto(false);
	}
}

void Match::user_ready(uint64_t uid) {
    (void)uid;
}

bool Match::check_room_full() const {
    return get_num_players() >= player_mode_;
}

bool Match::check_has_real_players() const {
    for (const auto& p : players_) {
        if (!p.is_empty() && !p.is_bot) {
            return true;
        }
    }
    return !viewers_.empty();
}

int Match::get_num_players() const {
    int count = 0;
    for (const auto& p : players_) {
        if (!p.is_empty()) {
            ++count;
        }
    }
    return count;
}

void Match::handle_register_leave_game(uint64_t uid, const packet::RegisterLeaveGame& req) {
    std::cout << "User " << uid << " register_leave_game with status " << req.status() << '\n';
    if (is_in_game_ && is_player(uid)) {
        if (req.status() == 0) {
            register_leave_uids_.insert(uid);
        } else {
            register_leave_uids_.erase(uid);
        }

        net_.send_packet(uid, Cmd::REGISTER_LEAVE_GAME, req);
        return;
    }

    user_leave(uid, 0);
}

void Match::end_game() {
    state_ = MatchState::Ended;
    time_start_ = -1;

    if (team_scores_[TEAM_ID_1] > team_scores_[TEAM_ID_2]) {
        win_team_id_ = TEAM_ID_1;
    }
    else {
        win_team_id_ = TEAM_ID_2;
    }

    std::vector<int64_t> uids;
    std::vector<int32_t> score_totals;
    std::vector<int32_t> score_last_tricks;
    std::vector<int32_t> score_cards;
    std::vector<int32_t> players_gold;

    for (const auto& player : players_) {
        uids.push_back(player.uid);
        score_cards.push_back(player.points - player.score_last_trick);
        score_last_tricks.push_back(player.score_last_trick);
        score_totals.push_back(player.points);
        players_gold.push_back(player.gold);
    }

    // Send to users
    packet::EndGame pkg;
    pkg.set_win_team_id(win_team_id_);

    for (auto uid : uids) {
        pkg.add_uids(uid);
    }
    for (auto score : score_cards) {
        pkg.add_score_cards(score);
    }
    for (auto score : score_last_tricks) {
        pkg.add_score_last_tricks(score);
    }
    for (auto score : score_totals) {
        pkg.add_score_totals(score);
    }
    for (auto gold : players_gold) {
        pkg.add_players_gold(gold);
    }

    delayed_tasks_.push_after(2.0, [this, pkg]() {
         broadcast_pkg(Cmd::END_GAME, pkg);
    });

    // kick users registered to leave after 2 seconds
    delayed_tasks_.push_after(6.0, [this]() {
        update_users_staying_endgame();
    });

    // schedule prepare for next game after delay
    delayed_tasks_.push_after(7.0, [this]() {
        if (check_room_full()) {
            prepare_start_game();
        } else {
            state_ = MatchState::Waiting;
        }
    });

    is_in_game_ = false;
}

void Match::start_game() {
    state_ = MatchState::Playing;
    time_start_ = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()
    ).count();
    is_in_game_ = true;

    std::cout << "Game started in match " << match_id_ << " at time " << time_start_ << '\n';

    // reset game-related states
    current_turn_idx_ = 0;
    cards_compare_.clear();
    cards_.clear();
    hand_suit_ = -1;
    cur_round_ = 0;
    hand_in_round_ = 0;
    current_round_ = 0;
    register_leave_uids_.clear();
    current_hand_ = 0;
    hand_in_round_ = -1;
    team_scores_ = {0, 0};
    last_won_uid_ = PLAYER_EMPTY_UID;

    for (auto& player : players_) {
        player.reset_new_game();

        cards_compare_.push_back(-1);
    }
    broadcast_pkg(Cmd::START_GAME, packet::StartGame{});

    delayed_tasks_.push_after(1.0, [this]() {
        handle_new_round();
    });
}

void Match::prepare_start_game() {
    state_ = MatchState::PreparingStart;
   
    int64_t now_ts = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()
    ).count();  
    time_start_ = now_ts + TIME_PREPARE_START;
    packet::PrepareStartGame pkg;
    broadcast_pkg(Cmd::PREPARE_START_GAME, pkg);
}

void Match::deal_cards() {
    cards_ = TRESSETTE_CARDS;

    std::random_device rd;
    std::mt19937 rng(rd());
    std::shuffle(cards_.begin(), cards_.end(), rng);

    for (size_t i = 0; i < players_.size(); ++i) {
        const size_t start = i * 10;
        const size_t end = (i + 1) * 10;
        players_[i].cards.assign(cards_.begin() + start, cards_.begin() + end);
    }

    // TEST CARDS, DO NOT USE LIVE
    // if (DEV_MODE) {
    //     players_[0].cards = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    // }

    cards_.erase(cards_.begin(), cards_.begin() + 10 * players_.size());

    for (const auto& player : players_) {
        if (player.is_bot) {
            continue;
        }

        packet::DealCard pkg;
        for (const auto card : player.cards) {
            pkg.add_cards(card);
        }
        pkg.set_remain_cards(static_cast<int>(cards_.size()));

        net_.send_packet(player.uid, Cmd::DEAL_CARD, pkg);
    }

    for (const auto uid : viewers_) {
        packet::DealCard pkg;
        pkg.set_remain_cards(static_cast<int>(cards_.size()));

        net_.send_packet(uid, Cmd::DEAL_CARD, pkg);
    }
}

void Match::handle_new_hand() {
    current_hand_ += 1;
    hand_suit_ = -1;
    hand_in_round_ += 1;

    // Next turn is the winner of last hand
    if (last_won_uid_ != PLAYER_EMPTY_UID) {
        const int idx = find_player_index(last_won_uid_);
        current_turn_idx_ = (idx >= 0) ? idx : 0;
    } else {
        current_turn_idx_ = 0;
    }

    if (current_turn_idx_ < 0 || static_cast<std::size_t>(current_turn_idx_) >= players_.size()) {
        return;
    }

    const auto now_ts = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()
    ).count();

    packet::NewHand pkg;
    pkg.set_current_turn(current_turn_idx_);
    broadcast_pkg(Cmd::NEW_HAND, pkg);

    players_[current_turn_idx_].on_turn();
}

void Match::handle_play_card(uint64_t uid, int card_id, bool is_auto) {
    if (state_ != MatchState::Playing) {
        return;
    }

    if (check_done_hand()) {
        return;
    }

    const int player_idx = find_player_index(uid);
    if (player_idx < 0) {
        return;
    }

    auto& player = players_[static_cast<std::size_t>(player_idx)];
    if (current_turn_idx_ != player_idx || player.is_empty()) {
        return;
    }

    if (!is_auto) {
        player.set_auto(false);
    }

    if (hand_suit_ != -1 && card_id % 4 != hand_suit_ && player.has_suit(hand_suit_)) {
        send_card_play_response(uid, PlayCardErrors::InvalidSuit);
        return;
    }

    if (!player.play_card(card_id)) {
        send_card_play_response(uid, PlayCardErrors::InvalidCard);
        return;
    }

    if (hand_suit_ == -1) {
        hand_suit_ = card_id % 4;
    }
    cards_compare_[player_idx] = card_id;
    bool is_finished_hand = check_done_hand();
    if (is_finished_hand) {
        current_turn_idx_ = -1;
    }
    else {
        current_turn_idx_ = (current_turn_idx_ + 1) % player_mode_;
		players_[static_cast<std::size_t>(current_turn_idx_)].on_turn();
    }

    packet::PlayCard pkg;
    pkg.set_uid(static_cast<int64_t>(uid));
    pkg.set_card_id(card_id);
    pkg.set_current_turn(current_turn_idx_);
    pkg.set_hand_suit(hand_suit_);
    pkg.set_is_auto(is_auto);

    if (is_finished_hand) {
        end_hand(pkg);
    } else {
        broadcast_pkg(Cmd::PLAY_CARD, pkg);
    }
}

void Match::send_card_play_response(uint64_t uid, PlayCardErrors status) {
    packet::PlayCardResponse pkg;
    pkg.set_status(static_cast<int>(status));
    net_.send_packet(uid, Cmd::PLAY_CARD_RESPONSE, pkg);
}

bool Match::check_done_hand() const {
    for (const auto& c : cards_compare_) {
        if (c == -1) {
            return false;
        }
    }
    return true;
}

void Match::end_hand(packet::PlayCard& play_card_pkg) {
    int win_card = get_win_card_in_hand();
    int win_score = get_win_score_in_hand();
    int win_player_idx = -1;
    for (std::size_t i = 0; i < cards_compare_.size(); ++i) {
        if (cards_compare_[i] == win_card) {
            win_player_idx = static_cast<int>(i);
            break;
        }
    }

    if (win_player_idx < 0 || static_cast<std::size_t>(win_player_idx) >= players_.size()) {
        std::cerr << "Invalid win_player_idx\n";
        return;
    }
    last_won_uid_ = players_[static_cast<std::size_t>(win_player_idx)].uid;
    MatchPlayer& win_player = players_[static_cast<std::size_t>(win_player_idx)];
    win_player.points += win_score;
    std::cout << "Player " << win_player.uid << " wins hand with card " << win_card
              << " and score " << win_score << " in match " << match_id_ << '\n';
    // reset cards_compare to -1
    for (auto& c : cards_compare_) {
        c = -1;
    }
    current_hand_ += 1;

    // If is end round
    bool is_end_round = cards_.empty() && players_[0].cards.empty();
    if (is_end_round) {
        // Bonus 1 point to winner of last hand in round
        win_player.points += 3; // 3 mean 1 point
        win_player.score_last_trick += 3;
    }

    play_card_pkg.set_win_uid(static_cast<int64_t>(win_player.uid));
    play_card_pkg.set_win_point(win_score);
    play_card_pkg.set_is_end_hand(true);
    play_card_pkg.set_win_card(win_card);
    play_card_pkg.set_is_end_round(is_end_round);
    
    for (const auto& player : players_) {
        play_card_pkg.add_player_points(player.points);
    }
    broadcast_pkg(Cmd::PLAY_CARD, play_card_pkg);

    if (check_end_game()) {
        end_game();
        return;
    }

    if (is_end_round) {
        handle_end_round();
    }
    else {
        bool has_remaining_cards = !cards_.empty();
        float delay_after_hand = 2.0f;
        if (has_remaining_cards) {
            delayed_tasks_.push_after(delay_after_hand, [this]() {
                 handle_draw_card();
            });
            delay_after_hand += 3.5f;
        }
        // Start new hand after 3 seconds to give clients time to receive end hand info
        delayed_tasks_.push_after(delay_after_hand, [this]() {
            handle_new_hand();
        });
    }
}

int Match::get_win_card_in_hand() const {
    std::vector<int> cards_valid;
    for (const auto card : cards_compare_) {
        if (card % 4 == hand_suit_) {
            cards_valid.push_back(card);
        }
    }

    if (cards_valid.empty()) {
        return -1;
    }

    int win_card = cards_valid[0];
    for (const auto card : cards_valid) {
        if (TRESSETTE_CARD_STRONGS.at(card / 4) > TRESSETTE_CARD_STRONGS.at(win_card / 4)) {
            win_card = card;
        }
    }

    return win_card;
}

int Match::get_win_score_in_hand() const {
    int score = 0;
    for (const auto card : cards_compare_) {
        score += TRESSETTE_CARD_VALUES.at(card);
    }
    return score;
}

void Match::handle_end_round() {
    std::cout << "Round " << cur_round_ << " ended in match " << match_id_ << '\n';

    // Start new round after 3 seconds to give clients time to receive end round info
    delayed_tasks_.push_after(4.0f, [this]() {
        handle_new_round();
    });
}

void Match::handle_new_round() {
    cur_round_ += 1;
    napoli_claimed_status_.clear();
    hand_in_round_ = -1;

    if (player_mode_ == PLAYER_SOLO_MODE) {
        for (auto& player : players_) {
            const int redundant_points = player.points % 3;
            player.points -= redundant_points;
        }
    } else {
        // Duo mode: trim redundant points by team
        int score_team_0 = 0;
        for (const auto& player : players_) {
            if (!player.is_empty() && player.team_id == 0) {
                score_team_0 += player.points;
            }
        }

        const int redundant_points_team_0 = score_team_0 % 3;
        if (redundant_points_team_0 > 0) {
            for (auto& player : players_) {
                if (!player.is_empty() && player.team_id == 0) {
                    const int redundant_player = player.points % 3;
                    player.points -= redundant_player;
                }
            }
        }

        int score_team_1 = 0;
        for (const auto& player : players_) {
            if (!player.is_empty() && player.team_id == 1) {
                score_team_1 += player.points;
            }
        }

        const int redundant_points_team_1 = score_team_1 % 3;
        if (redundant_points_team_1 > 0) {
            for (auto& player : players_) {
                if (!player.is_empty() && player.team_id == 1) {
                    const int redundant_player = player.points % 3;
                    player.points -= redundant_player;
                }
            }
        }
    }

    packet::NewRound pkg;
    pkg.set_current_round(cur_round_);

    for (const auto& player : players_) {
        pkg.add_players_gold(player.gold);
    }

    broadcast_pkg(Cmd::NEW_ROUND, pkg);

    delayed_tasks_.push_after(1.0f, [this]() {
        deal_cards();
    });

    delayed_tasks_.push_after(2.0f, [this]() {
        handle_new_hand();
    });
}

void Match::handle_draw_card() {
    std::vector<int> new_cards;
    for (size_t i = 0; i < players_.size(); ++i) {
        if (cards_.empty()) {
            break;
        }
        int card = cards_.back();
        cards_.pop_back();
        players_[i].cards.push_back(card);
        new_cards.push_back(card);
    }

    packet::DrawCard pkg;
    for (const auto card : new_cards) {
        pkg.add_cards(card);
    }
    broadcast_pkg(Cmd::DRAW_CARD, pkg);
}

void Match::user_disconnect(uint64_t uid) {
    std::cout << "User disconnect";
    if (!has_user(uid)) {
        return;
    }

    if (is_in_game_ && is_player(uid)) {
        return;
    }
    user_leave(uid);
}

bool Match::check_end_game() {
    // Check if one team reaches point_to_win, then end game
    team_scores_ = {0, 0};

    for (const auto& player : players_) {
        if (player.team_id < 0 || static_cast<std::size_t>(player.team_id) >= team_scores_.size()) {
            continue;
        }
        team_scores_[static_cast<std::size_t>(player.team_id)] += player.points;
    }

    // if (true) {
    //     return true;
    // }

    if (team_scores_[0] >= point_to_win_ || team_scores_[1] >= point_to_win_) {
        return true;
    }

    return false;
}

void Match::update_users_staying_endgame() {
    std::unordered_set<uint64_t> uids_to_kick;

    for (const auto& uid : register_leave_uids_) {
        uids_to_kick.insert(uid);
    }

 
    for (const auto& player : players_) {
        if (player.is_empty()) {
			continue;
        }
       
        if (player.is_bot || player.is_auto()) {
            uids_to_kick.insert(player.uid);
        }
    }

    for (const auto& uid : uids_to_kick) {
        user_leave(uid, 0);
    }
}

void Match::handle_game_action_napoli(int64_t uid)
{
    auto it = napoli_claimed_status_.find(uid);
    if (it != napoli_claimed_status_.end() && it->second) {
        return;
    }

    MatchPlayer* p = nullptr;
    for (auto& player : players_) {
        if (player.uid == uid) {
            p = &player;
            break;
        }
    }

    if (p == nullptr) {
        return;
    }

    auto napoli_sets = find_napoli(p->cards);
    if (napoli_sets.empty()) {
        return;
    }

    std::vector<int> napoli_suits;
    for (const auto& napoli_set : napoli_sets) {
        int set_suit = napoli_set[0] % 4;
        napoli_suits.push_back(set_suit);
    }

    napoli_claimed_status_[uid] = true;

    // Add 1 point for each Napoli set
    int point_add = static_cast<int>(napoli_sets.size()) * SERVER_SCORE_ONE_POINT;
    p->points += point_add;

    // Send to all users
    packet::GameActionNapoli pkg;
    pkg.set_uid(uid);
    pkg.set_point_add(point_add);
    for (int suit : napoli_suits) {
        pkg.add_suits(suit);
    }

    broadcast_pkg(Cmd::GAME_ACTION_NAPOLI, pkg);
}

std::vector<std::vector<int>> Match::find_napoli(const std::vector<int>& hand)
{
    std::vector<std::vector<int>> napoli_sets;

    // Check for Napoli in each suit
    for (int suit = 0; suit < 4; ++suit) {
        int ace = suit;
        int two = suit + 4;
        int three = suit + 8;

        if (std::find(hand.begin(), hand.end(), ace) != hand.end() &&
            std::find(hand.begin(), hand.end(), two) != hand.end() &&
            std::find(hand.begin(), hand.end(), three) != hand.end()) {
            napoli_sets.push_back({ ace, two, three });
        }
    }

    return napoli_sets;
}

void Match::handle_viewer_enter_match(uint64_t uid, int seat_idx)
{
    if (!is_viewer(uid)) {
        return;
    }
    if (seat_idx < 0 || seat_idx >= player_mode_) {
        return;
    }

	try_join(uid);
}

void Match::check_gen_bot() {
    if (!check_has_real_players()) {
        return;
    }

    int64_t now_ts_sec = std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::system_clock::now().time_since_epoch()
    ).count();
    
    if (now_ts_sec - last_time_changed_player_sec_ < time_gen_bot_interval_sec_) {
        return;
    }

    if (get_num_players() < player_mode_) {
		uint64_t bot_uid = users_info_mgr_.request_bot();
        if (bot_uid == -1) {
            return;
		}
        std::cout << "Generating bot with uid " << bot_uid << " for match " << match_id_ << '\n';
        try_join(bot_uid, true);
    }
}

void Match::schedule_gen_bot(){
    int64_t now_ts_sec = std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::system_clock::now().time_since_epoch()
    ).count();
    last_time_changed_player_sec_ = now_ts_sec;

    time_gen_bot_interval_sec_ = 5 + (std::rand() % 10); // random interval between 5 to 14 seconds
}

void Match::test_fill_bots() {
    for (int i = 0; i < player_mode_; ++i) {
        if (players_[i].is_empty()) {
            uint64_t bot_uid = users_info_mgr_.request_bot();
            if (bot_uid == -1) {
                return;
            }
            std::cout << "Filling bot with uid " << bot_uid << " in slot " << i << " for match " << match_id_ << '\n';
            try_join(bot_uid, true);
        }
    }
}