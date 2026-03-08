#pragma once

#include <string>

#include "packet.pb.h"

class AppConfig {
public:
    bool load();
    const packet::AppCodeVersion& app_code_version() const;

private:
    packet::AppCodeVersion app_code_version_;
};