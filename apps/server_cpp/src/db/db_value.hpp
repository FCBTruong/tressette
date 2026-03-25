#pragma once

#include <cstdint>
#include <optional>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <variant>

class DbValue {
public:
    using Storage = std::variant<std::nullptr_t, bool, std::int32_t, std::int64_t, double, std::string>;

    DbValue() : value_(nullptr) {}

    template <typename T>
    explicit DbValue(T value) : value_(std::move(value)) {}

    bool is_null() const;

    template <typename T>
    const T& as() const {
        if constexpr (std::is_same_v<T, std::optional<std::string>>) {
            if (is_null()) {
                static const std::optional<std::string> empty = std::nullopt;
                return empty;
            }
        }

        return std::get<T>(value_);
    }

    template <typename T>
    T value_or(T fallback) const {
        if (is_null()) {
            return fallback;
        }

        return std::get<T>(value_);
    }

    const Storage& storage() const;

private:
    Storage value_;
};
