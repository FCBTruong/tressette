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
    int port() const;

private:
    bool load_env();
    bool load_app_version();

private:
    packet::AppCodeVersion app_code_version_;

    std::string redis_url_;
    std::string db_url_;
    int port_ = 8000;
    EnvironmentMode environment_mode_ = EnvironmentMode::kUnknown;
};