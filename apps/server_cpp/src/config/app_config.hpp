#pragma once

#include <string>
#include "packet.pb.h"

class AppConfig {
public:
   enum class EnvironmentMode {
        kUnknown = 0,
        kDevelopment = 1,
        kLive = 2,
    };

    bool load();

    const packet::AppCodeVersion& app_code_version() const;
    const std::string& redis_url() const;
    const std::string& db_url() const;
    const std::string& telegram_bot_token() const;
    const std::string& telegram_chat_id() const;
    bool telegram_skip_tls_verify() const;
    bool telegram_enabled() const;
    int port() const;
    EnvironmentMode environment_mode() const;

private:
    bool load_env();
    bool load_app_version();

private:
    packet::AppCodeVersion app_code_version_;

    std::string redis_url_;
    std::string db_url_;
    std::string telegram_bot_token_;
    std::string telegram_chat_id_;
    bool telegram_skip_tls_verify_ = false;
    int port_ = 8000;
    EnvironmentMode environment_mode_ = EnvironmentMode::kUnknown;
};
