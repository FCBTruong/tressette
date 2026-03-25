#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "db/db_result.hpp"
#include "db/db_value.hpp"

class DbClient {
public:
    virtual ~DbClient() = default;

    virtual bool is_configured() const = 0;
    virtual bool connect() = 0;
    virtual bool is_connected() const = 0;
    virtual std::string last_error() const = 0;

    virtual DbResult execute(std::string_view sql, const std::vector<DbValue>& params = {}) = 0;
};
