#include "app_config.hpp"

#include <fstream>
#include <iostream>

#include <nlohmann/json.hpp>

using json = nlohmann::json;

namespace {
std::string trim(const std::string& value) {
    const std::size_t start = value.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) {
        return "";
    }

    const std::size_t end = value.find_last_not_of(" \t\r\n");
    return value.substr(start, end - start + 1);
}
}  // namespace

bool AppConfig::load() {
    if (!load_env()) {
        return false;
    }

    if (!load_app_version()) {
        return false;
    }

    return true;
}

bool AppConfig::load_env() {
    std::ifstream file(".env");
    if (!file.is_open()) {
        std::cerr << "Failed to open .env\n";
        return false;
    }

    std::string line;
    while (std::getline(file, line)) {
        line = trim(line);

        if (line.empty() || line[0] == '#') {
            continue;
        }

        const std::size_t pos = line.find('=');
        if (pos == std::string::npos) {
            continue;
        }

        const std::string key = trim(line.substr(0, pos));
        const std::string value = trim(line.substr(pos + 1));

        if (key == "REDIS_URL") {
            redis_url_ = value;
        } else if (key == "DB_URL") {
            db_url_ = value;
        }
        else if (key == "PORT") {
            try {
                port_ = static_cast<int>(std::stoul(value));
            } catch (const std::exception& e) {
                std::cerr << "Invalid PORT: " << value << ", error: " << e.what() << '\n';
                return false;
            }
        }
        else if (key == "ENVIRONMENT") {
            if (value == "dev") {
                environment_mode_ = EnvironmentMode::kDevelopment;
            } else if (value == "live") {
                environment_mode_ = EnvironmentMode::kLive;
            } else {
                std::cerr << "Invalid ENVIRONMENT: " << value << '\n';
                return false;
            }
        }
    }

    return true;
}

bool AppConfig::load_app_version() {
    std::ifstream file("config/app_version.json");
    if (!file.is_open()) {
        std::cerr << "Failed to open config/app_version.json\n";
        return false;
    }

    json data;
    file >> data;

    app_code_version_.set_android_version(
        data.value("android_version", 0)
    );
    app_code_version_.set_android_forced_update_version(
        data.value("android_forced_update_version", 0)
    );
    app_code_version_.set_android_remind_update_version(
        data.value("android_remind_update_version", 0)
    );

    app_code_version_.set_ios_version(
        data.value("ios_version", 0)
    );
    app_code_version_.set_ios_forced_update_version(
        data.value("ios_forced_update_version", 0)
    );
    app_code_version_.set_ios_remind_update_version(
        data.value("ios_remind_update_version", 0)
    );
    app_code_version_.set_ios_reviewing_version(
        data.value("ios_reviewing_version", 0)
    );

    return true;
}

const packet::AppCodeVersion& AppConfig::app_code_version() const {
    return app_code_version_;
}

const std::string& AppConfig::redis_url() const {
    return redis_url_;
}

const std::string& AppConfig::db_url() const {
    return db_url_;
}

int AppConfig::port() const {
    return port_;
}