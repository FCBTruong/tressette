#include "db/db_value.hpp"

bool DbValue::is_null() const {
    return std::holds_alternative<std::nullptr_t>(value_);
}

const DbValue::Storage& DbValue::storage() const {
    return value_;
}
