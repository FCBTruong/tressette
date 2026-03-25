#include "db/db_result.hpp"

#include <stdexcept>

bool DbResult::empty() const {
    return rows_.empty();
}

std::size_t DbResult::size() const {
    return rows_.size();
}

const DbRow& DbResult::front() const {
    if (rows_.empty()) {
        throw std::out_of_range("DbResult is empty");
    }

    return rows_.front();
}

const DbRow& DbResult::operator[](std::size_t index) const {
    return rows_.at(index);
}

DbResult::Storage::const_iterator DbResult::begin() const {
    return rows_.begin();
}

DbResult::Storage::const_iterator DbResult::end() const {
    return rows_.end();
}
