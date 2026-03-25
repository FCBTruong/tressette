#include "db/db_row.hpp"

void DbRow::set(std::string column, DbValue value) {
    columns_.insert_or_assign(std::move(column), std::move(value));
}

bool DbRow::has(std::string_view column) const {
    return columns_.find(std::string(column)) != columns_.end();
}

const DbValue& DbRow::at(std::string_view column) const {
    auto it = columns_.find(std::string(column));
    if (it == columns_.end()) {
        throw std::out_of_range("Column not found: " + std::string(column));
    }

    return it->second;
}
