// auth/auth_service.hpp
#pragma once

#include <cstdint>
#include <string>
#include <mutex>
#include <unordered_map>

class ClientSession;
class Packet;

struct LoginResult {
    bool success = false;
    uint64_t uid = 0;
    std::string session_token;
    int error = 0;
};

class AuthService {
public:
    AuthService() = default;

    // Handle login request data and return auth result.
    LoginResult login(
        const std::string& login_token,
        const std::string& platform,
        const std::string& device_model);

    // Check whether this session is allowed to use the packet.
    bool is_authorized(const ClientSession& session, const Packet& packet) const;

    // Commands that do not require auth.
    bool requires_auth(int cmd_id) const;

private:
    uint64_t get_or_create_uid_by_login_token(const std::string& login_token);
    std::string generate_session_token(uint64_t uid) const;
    mutable std::mutex mutex_;
    std::unordered_map<std::string, uint64_t> uid_by_login_token_;
    uint64_t next_uid_ = 100000;
};