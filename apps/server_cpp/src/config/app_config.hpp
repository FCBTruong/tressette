#pragma once

#include <string>

#include "packet.pb.h"

class AppConfig {
public:
    bool load();
    const AppCodeVersion& app_code_version() const;

private:
    AppCodeVersion app_code_version_;
};