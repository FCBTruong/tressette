#include "app_config.hpp"

#include <fstream>
#include <iostream>

#include <nlohmann/json.hpp>

using json = nlohmann::json;

bool AppConfig::load() {
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

const AppCodeVersion& AppConfig::app_code_version() const {
    return app_code_version_;
}