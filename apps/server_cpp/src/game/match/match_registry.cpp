#include "match_registry.hpp"

#include <iostream>

#include "match.hpp"
#include "net/cmd.hpp"
#include "packet.pb.h"
#include "match_player.hpp"

MatchRegistry::MatchRegistry(IGameClient& net, UsersInfoMgr& users_info_mgr) : net_(net), users_info_mgr_(users_info_mgr) {}

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
}

void MatchRegistry::on_received_packet(uint64_t uid, int cmd_id, const std::string& payload) {
    switch(cmd_id) {
        case Cmd::QUICK_PLAY:
            receive_quick_play(uid, payload);
            break;
        case Cmd::JOIN_TABLE_BY_ID:
            {
                packet::JoinTableById req;
                if (!req.ParseFromString(payload)) {
                    std::cerr << "Failed to parse JoinTableRequest from uid " << uid << '\n';
                    return;
                }
                handle_user_join_by_match_id(uid, req.match_id());
            }
        default:
            auto match = get_match_of_user(uid);
            if (!match) {
                return;
            }

            match->on_received_packet(uid, cmd_id, payload);
            break;
    }
}

std::shared_ptr<Match> MatchRegistry::create_match(
    int game_mode,
    int player_mode,
    bool is_private,
    int point_mode)
{
    const int64_t match_id = next_match_id_++;
    std::cout << "Creating match " << match_id << '\n';

    std::shared_ptr<Match> match;
    match = std::make_shared<Match>(
        match_id,
        player_mode,
        point_mode,
        net_,
        users_info_mgr_
    );
    
    match->set_public(!is_private);
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

std::shared_ptr<Match> MatchRegistry::get_match_of_viewer(uint64_t uid) const {
    const auto it = user_views_.find(uid);
    if (it == user_views_.end()) {
        return nullptr;
    }
    return get_match(it->second);
}

bool MatchRegistry::is_user_in_match(uint64_t uid) const {
    return user_match_ids_.find(uid) != user_match_ids_.end();
}

void MatchRegistry::destroy_match(int64_t match_id) {
    auto match = get_match(match_id);
    if (!match) {
        return;
    }

    for (const auto& player : match->players()) {
        user_match_ids_.erase(player->uid);
    }

    matches_.erase(match_id);
    std::cout << "Destroyed match " << match_id << '\n';
}

void MatchRegistry::user_join_match(const std::shared_ptr<Match>& match, uint64_t uid) {
    if (!match) {
        return;
    }

    const auto view_it = user_views_.find(uid);
    if (view_it != user_views_.end()) {
        const int64_t viewed_match_id = view_it->second;
        user_views_.erase(view_it);

        auto viewed_match = get_match(viewed_match_id);
        if (viewed_match) {
            const bool is_same_match = (viewed_match_id == match->match_id());
            viewed_match->user_stop_view(uid, !is_same_match);
        }
    }

    user_match_ids_[uid] = match->match_id();
    match->user_join(uid);
}

void MatchRegistry::user_disconnect(uint64_t uid) {
    // auto match = get_match_of_user(uid);
    // if (match && match->state() == MatchState::Waiting) {
    //     handle_user_leave_match(uid);
    // }

    // auto view_match = get_match_of_viewer(uid);
    // if (view_match) {
    //     view_match->user_stop_view(uid);
    //     user_views_.erase(uid);

    //     if (!view_match->check_has_real_players()) {
    //         destroy_match(view_match->match_id());
    //     }
    // }
}

void MatchRegistry::handle_user_stop_view(uint64_t uid) {
    const auto it = user_views_.find(uid);
    if (it == user_views_.end()) {
        return;
    }

    const int64_t match_id = it->second;
    user_views_.erase(it);

    auto match = get_match(match_id);
    if (match && !match->check_has_real_players()) {
        destroy_match(match_id);
    }
}

std::shared_ptr<Match> MatchRegistry::find_a_suitable_match_quickplay() const {
    for (const auto& [match_id, match] : matches_) {
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
    if (is_user_in_match(uid)) {
        send_response_join_table(uid, JoinMatchErrors::AlreadyInMatch);
        return;
    }

    auto match = get_match(match_id);
    if (!match) {
        send_response_join_table(uid, JoinMatchErrors::MatchNotFound);
        return;
    }

    if (match->state() != MatchState::Waiting) {
        send_response_join_table(uid, JoinMatchErrors::MatchStarted);
        return;
    }

    if (match->check_room_full()) {
        send_response_join_table(uid, JoinMatchErrors::FullRoom);
        return;
    }

    user_join_match(match, uid);
    send_response_join_table(uid, JoinMatchErrors::Success);
}

void MatchRegistry::receive_user_join_match(uint64_t uid, const std::string& payload) {
    packet::JoinTableById pkg;
    if (!pkg.ParseFromString(payload)) {
        return;
    }

    handle_user_join_by_match_id(uid, pkg.match_id());
}

void MatchRegistry::handle_quick_play(uint64_t uid) {
    // log
    std::cout << "Handling quick play for user: " << uid << std::endl;
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
            pkg.add_avatars(player->avatar);
            pkg.add_player_uids(static_cast<int64_t>(player->uid));
            pkg.add_avatar_frames(player->avatar_frame);
        }
    }
}

void MatchRegistry::view_game(uint64_t uid, const std::string& payload) {
    packet::ViewGame pkg;
    if (!pkg.ParseFromString(payload)) {
        return;
    }

    auto match = get_match(pkg.match_id());
    if (!match) {
        return;
    }

    user_views_[uid] = pkg.match_id();
    match->user_view_game(uid);
}

void MatchRegistry::send_response_join_table(uint64_t uid, JoinMatchErrors status) {
    packet::JoinTableResponse pkg;
    pkg.set_error(static_cast<int>(status));

    std::string payload;
    if (!pkg.SerializeToString(&payload)) {
        return;
    }

    net_.send_packet(uid, Cmd::JOIN_TABLE_BY_ID, pkg);
}