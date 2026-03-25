#pragma once

#include <vector>

#include "db/db_row.hpp"

class DbResult {
public:
    using Storage = std::vector<DbRow>;

    DbResult() = default;
    explicit DbResult(Storage rows) : rows_(std::move(rows)) {}

    bool empty() const;
    std::size_t size() const;

    const DbRow& front() const;
    const DbRow& operator[](std::size_t index) const;

    Storage::const_iterator begin() const;
    Storage::const_iterator end() const;

private:
    Storage rows_;
};
