#include "match.hpp"

#include <algorithm>
#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>
#include "packet.pb.h"
#include "match_player.hpp"  // must define MatchPlayer with at least: uid, is_bot

Match::Match(int64_t match_id, int player_mode, int point_mode,
             IGameClient& net, UsersInfoMgr& users_info_mgr)
    : net_(net),
      users_info_mgr_(users_info_mgr),
      match_id_(match_id),
      player_mode_(player_mode),
      point_mode_(point_mode) 
{
    players_.resize(static_cast<std::size_t>(player_mode_));
}

void Match::on_received_packet(uint64_t uid, int cmd_id, const std::string& payload) {
    switch (cmd_id) {
        case Cmd::USER_READY_MATCH:
            user_ready(uid);
            return;

        case Cmd::USER_RETURN_TO_TABLE:
            user_return_to_table(uid);
            return;

        case Cmd::VIEW_GAME:
            user_view_game(uid);
            return;

        case Cmd::USER_STOP_VIEW:
            user_stop_view(uid, true);
            return;

        case Cmd::NEW_INGAME_CHAT_MESSAGE: {
            packet::InGameChatMessage req;
            if (!req.ParseFromString(payload)) return;
            broadcast_chat_message(uid, req.chat_message());
            return;
        }

        case Cmd::CHAT_EMOTICON: {
            packet::InGameChatEmoticon req;
            if (!req.ParseFromString(payload)) return;
            broadcast_chat_emoticon(uid, req.emoticon());
            return;
        }

        default:
            // Game-specific commands handled in derived (PLAY_CARD, NAPOLI, ...)
            return;
    }
}

void Match::broadcast_pkg(Cmd cmd, const google::protobuf::Message& msg, const std::vector<uint64_t>& exclude_uids) {
    packet::Packet pkg;
    pkg.set_cmd_id(static_cast<int>(cmd));
    if (!msg.SerializeToString(pkg.mutable_payload())) {
        return;
    }

    std::unordered_map<uint64_t, bool> exclude_map;
    for (const auto& uid : exclude_uids) {
        exclude_map[uid] = true;
    }

    for (const auto& player : players()) {
        if (player && !exclude_map[player->uid]) {
            // Send package to player
        }
    }
}

void Match::user_join(uint64_t user_id, bool is_bot) {
    // check if already in match
    for (const auto& p : players()) {
        if (p && p->uid == user_id) {
            return;
        }
    }

    // Find empty slot and add player
    int slot_idx = -1;
    auto& ps = players();
    for (std::size_t i = 0; i < ps.size(); ++i) {
        if (!ps[i]) {
            slot_idx = static_cast<int>(i);
            break;
        }
    }

    packet::NewUserJoinMatch pkg;
    pkg.set_uid(static_cast<int64_t>(user_id));

    // broadt cast to all players in the match
    broadcast_pkg(Cmd::NEW_USER_JOIN_MATCH, pkg, std::vector<uint64_t>{user_id});
    send_game_info_to_user(user_id);
}

void Match::send_game_info_to_user(uint64_t uid) {
    std::cout << "Sending game info to user " << uid << " in match " << match_id() << '\n';
    packet::GameInfo game_info;

    game_info.set_match_id(match_id());
    game_info.set_game_mode(game_mode());
    game_info.set_player_mode(player_mode());
    game_info.set_game_state(static_cast<int>(state()));
    game_info.set_current_turn(current_turn_);
    for (int c : cards_compare_) {
        game_info.add_cards_compare(c);
    }
    game_info.set_remain_cards(static_cast<int>(cards_.size()));
    game_info.set_hand_suit(hand_suit_);
    game_info.set_is_registered_leave(register_leave_uids_.count(uid) > 0);
    game_info.set_current_round(cur_round_);
    game_info.set_hand_in_round(hand_in_round_);
    game_info.set_point_to_win(point_to_win_);

    // players
    for (const auto& p : players_) {
        const uint64_t puid = p ? p->uid : static_cast<uint64_t>(-1);

        game_info.add_uids(static_cast<int64_t>(puid));
        game_info.add_user_golds(p ? static_cast<int64_t>(p->gold) : 0);
        game_info.add_user_names(p ? p->name : std::string{});
        game_info.add_user_points(p ? p->points : 0);
        game_info.add_team_ids(p ? p->team_id : -1);
        game_info.add_avatars(p ? p->avatar : std::string{});
        game_info.add_avatar_frames(p ? p->avatar_frame : 0);
        game_info.add_is_vips(false);

        if (p && puid == uid) {
            for (int card : p->cards) game_info.add_my_cards(card);
        }
    }

    // viewers
    for (uint64_t viewer_uid : viewers_) {
        const auto vinfo = users_info_mgr_.get_or_create(viewer_uid);
        game_info.add_viewer_uids(static_cast<int64_t>(viewer_uid));
        game_info.add_viewer_avatars(vinfo.avatar);
        game_info.add_viewer_names(vinfo.name);
        game_info.add_viewer_avatar_frames(vinfo.avatar_frame);
    }

    net_.send_packet(uid, Cmd::GAME_INFO, game_info);
}

void Match::user_leave(uint64_t uid, int /*reason*/) {
    
}

void Match::user_reconnect(uint64_t uid) {
   
}

void Match::loop() {
    
}

void Match::broadcast_chat_emoticon(uint64_t /*uid*/, int /*emoticon*/) {

}

void Match::broadcast_chat_message(uint64_t /*uid*/, const std::string& /*message*/) {
   
}

void Match::user_return_to_table(uint64_t uid) {

}

void Match::user_ready(uint64_t /*uid*/) {
}

bool Match::check_room_full() const {
   return false;
}

void Match::user_stop_view(uint64_t uid, bool /*should_send_back_to_user*/) {
    viewers_.erase(uid);
}

void Match::user_view_game(uint64_t uid) {
    viewers_.insert(uid);
}

bool Match::check_has_real_players() const {
    // Real players = seated non-bot with uid != -1 OR any viewers
    for (const auto& p : players()) {
        if (p && p->uid != static_cast<uint64_t>(-1) && !p->is_bot) return true;
    }
    return !viewers_.empty();
}

int Match::get_num_players() const {
    int c = 0;
    for (const auto& p : players()) {
        if (p && p->uid != static_cast<uint64_t>(-1)) ++c;
    }
    return c;
}