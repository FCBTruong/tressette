// net/session_registry.cpp
#include "session_registry.hpp"
#include <vector>
#include "client_session.hpp"

void SessionRegistry::add_session(const std::shared_ptr<ClientSession>& session) {
    if (!session) {
        return;
    }

    std::lock_guard<std::mutex> lock(mutex_);
    sessions_by_id_[session->session_id()] = session;
}

void SessionRegistry::remove_session(uint64_t session_id) {
    std::lock_guard<std::mutex> lock(mutex_);

    sessions_by_id_.erase(session_id);

    for (auto it = session_id_by_uid_.begin(); it != session_id_by_uid_.end();) {
        if (it->second == session_id) {
            it = session_id_by_uid_.erase(it);
        } else {
            ++it;
        }
    }
}

bool SessionRegistry::bind_uid(uint64_t uid, uint64_t session_id)
{
    std::shared_ptr<ClientSession> old_session;

    {
        std::lock_guard<std::mutex> lock(mutex_);

        const auto session_it = sessions_by_id_.find(session_id);
        if (session_it == sessions_by_id_.end()) {
            return false;
        }

        const auto uid_it = session_id_by_uid_.find(uid);
        if (uid_it != session_id_by_uid_.end()) {
            const uint64_t old_session_id = uid_it->second;

            if (old_session_id != session_id) {
                const auto old_session_it = sessions_by_id_.find(old_session_id);
                if (old_session_it != sessions_by_id_.end()) {
                    old_session = old_session_it->second;
                }
            }
        }

        session_id_by_uid_[uid] = session_id;
    }

    if (old_session) {
        old_session->clear_auth();
        old_session->close();
    }

    return true;
}

void SessionRegistry::unbind_uid(uint64_t uid) {
    std::lock_guard<std::mutex> lock(mutex_);
    session_id_by_uid_.erase(uid);
}

std::shared_ptr<ClientSession> SessionRegistry::find_by_session_id(uint64_t session_id) const {
    std::lock_guard<std::mutex> lock(mutex_);

    const auto it = sessions_by_id_.find(session_id);
    if (it == sessions_by_id_.end()) {
        return nullptr;
    }

    return it->second;
}

std::shared_ptr<ClientSession> SessionRegistry::find_by_uid(uint64_t uid) const {
    std::lock_guard<std::mutex> lock(mutex_);

    const auto uid_it = session_id_by_uid_.find(uid);
    if (uid_it == session_id_by_uid_.end()) {
        return nullptr;
    }

    const auto session_it = sessions_by_id_.find(uid_it->second);
    if (session_it == sessions_by_id_.end()) {
        return nullptr;
    }

    return session_it->second;
}

bool SessionRegistry::is_online(uint64_t uid) const {
    std::lock_guard<std::mutex> lock(mutex_);

    const auto uid_it = session_id_by_uid_.find(uid);
    if (uid_it == session_id_by_uid_.end()) {
        return false;
    }

    return sessions_by_id_.find(uid_it->second) != sessions_by_id_.end();
}

std::size_t SessionRegistry::session_count() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return sessions_by_id_.size();
}

std::size_t SessionRegistry::online_user_count() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return session_id_by_uid_.size();
}