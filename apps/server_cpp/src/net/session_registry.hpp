// net/session_registry.hpp
#pragma once

#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_map>

class ClientSession;

class SessionRegistry {
public:
    SessionRegistry() = default;
    ~SessionRegistry() = default;

    SessionRegistry(const SessionRegistry&) = delete;
    SessionRegistry& operator=(const SessionRegistry&) = delete;

    // Register a newly accepted socket session.
    void add_session(const std::shared_ptr<ClientSession>& session);

    // Remove a disconnected session by session id.
    void remove_session(uint64_t session_id);

    // Bind a logged-in user uid to an existing session.
    // Returns false if the session does not exist.
    bool bind_uid(uint64_t uid, uint64_t session_id);

    // Remove uid mapping only.
    void unbind_uid(uint64_t uid);

    // Lookup helpers.
    std::shared_ptr<ClientSession> find_by_session_id(uint64_t session_id) const;
    std::shared_ptr<ClientSession> find_by_uid(uint64_t uid) const;

    // Status helpers.
    bool is_online(uint64_t uid) const;
    std::size_t session_count() const;
    std::size_t online_user_count() const;

private:
    mutable std::mutex mutex_;

    // All connected sessions, including unauthenticated ones.
    std::unordered_map<uint64_t, std::shared_ptr<ClientSession>> sessions_by_id_;

    // Only logged-in users.
    std::unordered_map<uint64_t, uint64_t> session_id_by_uid_;
};