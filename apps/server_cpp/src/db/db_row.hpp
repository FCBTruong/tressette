#pragma once

#include <stdexcept>
#include <string>
#include <unordered_map>

#include "db/db_value.hpp"

class DbRow {
public:
    void set(std::string column, DbValue value);
    bool has(std::string_view column) const;

    template <typename T>
    T get(std::string_view column) const {
        const DbValue& value = at(column);
        return value.as<T>();
    }

    const DbValue& at(std::string_view column) const;

private:
    std::unordered_map<std::string, DbValue> columns_;
};
