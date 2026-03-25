#include "db/orm/sql_builder.hpp"

#include <sstream>

std::string SqlBuilder::select_all(std::string_view table, const std::vector<std::string_view>& columns) {
    return "SELECT " + join(columns, ", ") + " FROM " + std::string(table);
}

std::string SqlBuilder::select_where_eq(std::string_view table,
                                        const std::vector<std::string_view>& columns,
                                        std::string_view where_column,
                                        int placeholder_index) {
    std::ostringstream stream;
    stream << select_all(table, columns) << " WHERE " << where_column << " = $" << placeholder_index;
    return stream.str();
}

std::string SqlBuilder::insert(std::string_view table, const std::vector<std::string_view>& columns) {
    std::ostringstream placeholders;
    for (std::size_t i = 0; i < columns.size(); ++i) {
        if (i > 0) {
            placeholders << ", ";
        }
        placeholders << "$" << (i + 1);
    }

    std::ostringstream stream;
    stream << "INSERT INTO " << table << " (" << join(columns, ", ") << ") VALUES (" << placeholders.str() << ")";
    return stream.str();
}

std::string SqlBuilder::update_where_eq(std::string_view table,
                                        const std::vector<std::string_view>& columns,
                                        std::string_view where_column,
                                        int where_placeholder_index) {
    std::ostringstream assignments;
    for (std::size_t i = 0; i < columns.size(); ++i) {
        if (i > 0) {
            assignments << ", ";
        }
        assignments << columns[i] << " = $" << (i + 1);
    }

    std::ostringstream stream;
    stream << "UPDATE " << table << " SET " << assignments.str()
           << " WHERE " << where_column << " = $" << where_placeholder_index;
    return stream.str();
}

std::string SqlBuilder::join(const std::vector<std::string_view>& parts, std::string_view separator) {
    std::ostringstream stream;
    for (std::size_t i = 0; i < parts.size(); ++i) {
        if (i > 0) {
            stream << separator;
        }
        stream << parts[i];
    }

    return stream.str();
}
