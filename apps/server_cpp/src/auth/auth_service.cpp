// auth/auth_service.cpp
#include "auth_service.hpp"

#include <random>
#include <sstream>

#include "net/client_session.hpp"
#include "net/cmd.hpp"
#include "packet.pb.h"

LoginResult AuthService::login(
    const std::string& login_token,
    const std::string& platform,
    const std::string& device_model)
{
    LoginResult result;

    // In real implementation, you would have a user database and proper authentication.
    if (login_token.empty()) {
        result.success = false;
        result.error = 1;
        return result;
    }

    (void)platform;
    (void)device_model;

    result.success = true;

    // For simplicity, we use login_token as the key to get/create uid.
    // In real implementation, you would have a user database and proper authentication.
    result.uid = get_or_create_uid_by_login_token(login_token);
    result.session_token = generate_session_token(result.uid);
    result.error = 0;

    return result;
}

bool AuthService::is_authorized(const ClientSession& session, const packet::Packet& packet) const
{
    if (!requires_auth(packet.cmd_id())) {
        return true;
    }

    if (!session.is_authenticated()) {
        return false;
    }

    return session.session_token() == packet.token();
}

bool AuthService::requires_auth(int cmd_id) const
{
    switch (cmd_id) {
        case Cmd::PING_PONG:
        case Cmd::LOGIN:
        case Cmd::APP_VERSION:
            return false;
        default:
            return true;
    }
}

std::string AuthService::generate_session_token(uint64_t uid) const
{
    std::random_device rd;
    std::mt19937_64 gen(rd());
    std::uniform_int_distribution<uint64_t> dist;

    std::ostringstream oss;
    oss << uid << "_" << dist(gen);
    return oss.str();
}

uint64_t AuthService::get_or_create_uid_by_login_token(const std::string& login_token)
{
    std::lock_guard<std::mutex> lock(mutex_);

    const auto it = uid_by_login_token_.find(login_token);
    if (it != uid_by_login_token_.end()) {
        return it->second;
    }

    const uint64_t new_uid = next_uid_++;
    uid_by_login_token_[login_token] = new_uid;
    return new_uid;
}