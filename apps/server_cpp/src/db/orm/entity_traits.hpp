#pragma once

#include <string_view>
#include <vector>

template <typename T>
struct OrmEntityTraits;

template <typename T>
concept OrmEntity = requires {
    { OrmEntityTraits<T>::table_name() } -> std::convertible_to<std::string_view>;
    { OrmEntityTraits<T>::columns() } -> std::convertible_to<std::vector<std::string_view>>;
};
