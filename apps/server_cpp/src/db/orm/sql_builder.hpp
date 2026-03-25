#pragma once

#include <string>
#include <string_view>
#include <vector>

class SqlBuilder {
public:
    static std::string select_all(std::string_view table, const std::vector<std::string_view>& columns);
    static std::string select_where_eq(std::string_view table,
                                       const std::vector<std::string_view>& columns,
                                       std::string_view where_column,
                                       int placeholder_index = 1);
    static std::string insert(std::string_view table, const std::vector<std::string_view>& columns);
    static std::string update_where_eq(std::string_view table,
                                       const std::vector<std::string_view>& columns,
                                       std::string_view where_column,
                                       int where_placeholder_index);

private:
    static std::string join(const std::vector<std::string_view>& parts, std::string_view separator);
};
