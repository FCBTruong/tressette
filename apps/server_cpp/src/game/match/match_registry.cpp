#include "match_registry.hpp"

#include <iostream>

#include "match_player.hpp"
#include "net/cmd.hpp"
#include "packet.pb.h"

MatchRegistry::MatchRegistry(IGameClient& net, UsersInfoMgr& users_info_mgr)
    : net_(net), users_info_mgr_(users_info_mgr) {

}

void MatchRegistry::start() {
    running_ = true;
}

void MatchRegistry::stop() {
    running_ = false;
}

void MatchRegistry::update() {
    if (!running_) {
        return;
    }

    for (auto& [match_id, match] : matches_) {
        if (match) {
            match->loop();
        }
    }

    flush_pending_destroy_matches();
}

void MatchRegistry::on_received_packet(uint64_t uid, Cmd cmd_id, const std::string& payload) {
    switch (cmd_id) {
        case Cmd::QUICK_PLAY:
            receive_quick_play(uid, payload);
            break;

        case Cmd::JOIN_TABLE_BY_ID: {
            receive_user_join_match(uid, payload);
            break;
        }
        
        case Cmd::TABLE_LIST: {
            receive_request_table_list(uid);
            break;
        }

        default: {
            auto match = get_match_of_user(uid);
            if (!match) {
                return;
            }

            match->on_received_packet(uid, cmd_id, payload);
            break;
        }
    }
}

std::shared_ptr<Match> MatchRegistry::create_match(
    int game_mode,
    int player_mode,
    bool is_private,
    int point_mode
) {
    (void)game_mode;

    const int64_t match_id = next_match_id_++;
    std::cout << "Creating match " << match_id << '\n';

    auto match = std::make_shared<Match>(
        match_id,
        player_mode,
        point_mode,
        net_,
        users_info_mgr_
    );

    match->set_public(!is_private);

    match->set_user_removed_callback(
        [this](uint64_t uid, int64_t removed_match_id) {
            on_user_removed_from_match(uid, removed_match_id);
        }
    );

    matches_[match_id] = match;
    return match;
}

std::shared_ptr<Match> MatchRegistry::get_match(int64_t match_id) const {
    const auto it = matches_.find(match_id);
    if (it == matches_.end()) {
        return nullptr;
    }
    return it->second;
}

std::shared_ptr<Match> MatchRegistry::get_match_of_user(uint64_t uid) const {
    const auto it = user_match_ids_.find(uid);
    if (it == user_match_ids_.end()) {
        return nullptr;
    }
    return get_match(it->second);
}

bool MatchRegistry::is_user_in_match(uint64_t uid) const {
    return user_match_ids_.find(uid) != user_match_ids_.end();
}

void MatchRegistry::destroy_match_now(int64_t match_id) {
    auto match = get_match(match_id);
    if (!match) {
        return;
    }

    for (const auto& player : match->players()) {
        if (!player.is_empty()) {
            user_match_ids_.erase(player.uid);
        }
    }

    for (const auto viewer_uid : match->viewers()) {
        user_match_ids_.erase(viewer_uid);
    }

    matches_.erase(match_id);
    std::cout << "Destroyed match " << match_id << '\n';
}

void MatchRegistry::flush_pending_destroy_matches() {
    std::vector<int64_t> match_ids(
        pending_destroy_match_ids_.begin(),
        pending_destroy_match_ids_.end()
    );
    pending_destroy_match_ids_.clear();

    for (int64_t match_id : match_ids) {
        destroy_match_now(match_id);
    }
}

void MatchRegistry::request_destroy_match(int64_t match_id) {
    auto match = get_match(match_id);
    if (!match) {
        return;
    }
	match->set_is_pending_destroyed(true);
    pending_destroy_match_ids_.insert(match_id);
}

bool MatchRegistry::user_join_match(const std::shared_ptr<Match>& match, uint64_t uid) {
    if (!match) {
        return false;
    }
    const auto result = match->try_join(uid);

    if (result != JoinMatchErrors::Success) {
        send_response_join_table(uid, result);
        return false;
    }

    user_match_ids_[uid] = match->match_id();
    return true;
}

void MatchRegistry::user_disconnect(uint64_t uid) {
    auto match = get_match_of_user(uid);
    if (!match) {
        return;
    }

    match->user_disconnect(uid);
}

std::shared_ptr<Match> MatchRegistry::find_a_suitable_match_quickplay() const {
    for (const auto& [match_id, match] : matches_) {
        (void)match_id;

        if (!match) {
            continue;
        }
        if (!match->is_public()) {
            continue;
        }
        if (match->state() == MatchState::Waiting && !match->check_room_full()) {
            return match;
        }
    }

    return nullptr;
}

std::vector<std::shared_ptr<Match>> MatchRegistry::prioritize_matches(uint64_t /*uid*/) const {
    std::vector<std::shared_ptr<Match>> waiting;
    std::vector<std::shared_ptr<Match>> others;

    for (const auto& [match_id, match] : matches_) {
        (void)match_id;

        if (!match) {
            continue;
        }

        if (match->state() == MatchState::Waiting) {
            waiting.push_back(match);
        } else {
            others.push_back(match);
        }
    }

    waiting.insert(waiting.end(), others.begin(), others.end());

    constexpr std::size_t kMaxMatches = 20;
    if (waiting.size() > kMaxMatches) {
        waiting.resize(kMaxMatches);
    }

    return waiting;
}

void MatchRegistry::handle_user_join_by_match_id(uint64_t uid, int64_t match_id) {
    auto match = get_match(match_id);
    if (!match) {
        send_response_join_table(uid, JoinMatchErrors::MatchNotFound);
        return;
    }
    user_join_match(match, uid);
}

void MatchRegistry::receive_user_join_match(uint64_t uid, const std::string& payload) {
    packet::JoinTableById pkg;
    if (!pkg.ParseFromString(payload)) {
        return;
    }

    handle_user_join_by_match_id(uid, pkg.match_id());
}

void MatchRegistry::handle_quick_play(uint64_t uid) {
    std::cout << "Handling quick play for user: " << uid << '\n';

    auto existing = get_match_of_user(uid);
    if (existing) {
        existing->user_reconnect(uid);
        return;
    }

    auto match = find_a_suitable_match_quickplay();
    if (!match) {
        std::cout << "No suitable match found for quick play, creating a new one.\n";
        match = create_match(TRESSETTE_MODE, PLAYER_SOLO_MODE, false, 21);
        if (!match) {
            return;
        }
    }

//    for (int i = 0; i < 10; i++) {
//        // test
// 		auto test_match = create_match(TRESSETTE_MODE, PLAYER_SOLO_MODE, false, 21);
//        test_match->test_fill_bots();
//    }

    std::cout << "User " << uid << " joining match " << match->match_id() << " via quick play.\n";
    user_join_match(match, uid);
}

void MatchRegistry::receive_quick_play(uint64_t uid, const std::string& payload) {
    packet::QuickPlay pkg;
    if (!pkg.ParseFromString(payload)) {
        return;
    }

    handle_quick_play(uid);
}

void MatchRegistry::received_create_table(uint64_t uid, const std::string& payload) {
    packet::CreateTable pkg;
    if (!pkg.ParseFromString(payload)) {
        return;
    }

    const int game_mode = TRESSETTE_MODE;
    int player_mode = pkg.player_mode();
    int point_mode = pkg.point_mode();
    const bool is_private = pkg.is_private();

    if (point_mode != 11 && point_mode != 21) {
        return;
    }

    if (player_mode != PLAYER_SOLO_MODE && player_mode != PLAYER_DUO_MODE) {
        return;
    }

    if (player_mode == PLAYER_DUO_MODE) {
        point_mode = 21;
    }

    if (is_user_in_match(uid)) {
        return;
    }

    auto match = create_match(game_mode, player_mode, is_private, point_mode);
    if (!match) {
        return;
    }

    user_join_match(match, uid);
}

void MatchRegistry::receive_request_table_list(uint64_t uid) {
    (void)uid;

    auto matches = prioritize_matches(uid);
    packet::TableList pkg;

    for (const auto& match : matches) {
        if (!match) {
            continue;
        }

        pkg.add_table_ids(match->match_id());
        pkg.add_player_modes(match->player_mode());
        pkg.add_num_players(match->get_num_players());
        pkg.add_game_modes(match->game_mode());
        pkg.add_is_private(!match->is_public());

        for (const auto& player : match->players()) {
            pkg.add_avatars(player.avatar);
            pkg.add_player_uids(static_cast<int64_t>(player.uid));
            pkg.add_avatar_frames(player.avatar_frame);
            pkg.add_points(player.points);
        }
    }

    net_.send_packet(uid, Cmd::TABLE_LIST, pkg);
}

void MatchRegistry::send_response_join_table(uint64_t uid, JoinMatchErrors status) {
    packet::JoinTableResponse pkg;
    pkg.set_error(static_cast<int>(status));
    net_.send_packet(uid, Cmd::JOIN_TABLE_BY_ID, pkg);
}

void MatchRegistry::on_user_removed_from_match(uint64_t uid, int64_t match_id) {
    const auto it = user_match_ids_.find(uid);
    if (it != user_match_ids_.end() && it->second == match_id) {
        user_match_ids_.erase(it);
    }

    auto match = get_match(match_id);
    if (!match) {
        return;
    }

    if (!match->check_has_real_players()) {
        request_destroy_match(match_id);
    }
}

void MatchRegistry::on_user_login(uint64_t uid) {
    auto match = get_match_of_user(uid);
    if (match) {
        match->user_reconnect(uid);
    }
}