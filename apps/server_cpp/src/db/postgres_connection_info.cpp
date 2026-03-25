#include "db/postgres_connection_info.hpp"

#include <sstream>

namespace {
std::string extract_query_value(const std::string& query, const std::string& key) {
    const std::string needle = key + "=";
    std::size_t start = query.find(needle);
    if (start == std::string::npos) {
        return "";
    }

    start += needle.size();
    const std::size_t end = query.find('&', start);
    return query.substr(start, end == std::string::npos ? std::string::npos : end - start);
}
}  // namespace

PostgresConnectionInfo PostgresConnectionInfo::from_connection_string(std::string connection_string) {
    PostgresConnectionInfo info;
    info.connection_string_ = trim_quotes(std::move(connection_string));

    const std::size_t scheme_end = info.connection_string_.find("://");
    if (scheme_end == std::string::npos) {
        return info;
    }

    info.scheme_ = info.connection_string_.substr(0, scheme_end);
    std::string remainder = info.connection_string_.substr(scheme_end + 3);

    const std::size_t query_start = remainder.find('?');
    if (query_start != std::string::npos) {
        const std::string query = remainder.substr(query_start + 1);
        info.ssl_mode_ = extract_query_value(query, "sslmode");
        remainder = remainder.substr(0, query_start);
    }

    const std::size_t at_pos = remainder.find('@');
    std::string authority = remainder;
    if (at_pos != std::string::npos) {
        const std::string credentials = remainder.substr(0, at_pos);
        authority = remainder.substr(at_pos + 1);

        const std::size_t colon_pos = credentials.find(':');
        if (colon_pos == std::string::npos) {
            info.user_ = credentials;
        } else {
            info.user_ = credentials.substr(0, colon_pos);
            info.password_ = credentials.substr(colon_pos + 1);
        }
    }

    const std::size_t slash_pos = authority.find('/');
    std::string host_port = authority;
    if (slash_pos != std::string::npos) {
        host_port = authority.substr(0, slash_pos);
        info.database_ = authority.substr(slash_pos + 1);
    }

    const std::size_t colon_pos = host_port.rfind(':');
    if (colon_pos == std::string::npos) {
        info.host_ = host_port;
    } else {
        info.host_ = host_port.substr(0, colon_pos);
        const std::string port_part = host_port.substr(colon_pos + 1);
        if (!port_part.empty()) {
            info.port_ = static_cast<std::uint16_t>(std::stoul(port_part));
        }
    }

    return info;
}

bool PostgresConnectionInfo::valid() const {
    return (scheme_ == "postgres" || scheme_ == "postgresql") &&
           !host_.empty() &&
           !database_.empty();
}

std::string PostgresConnectionInfo::summary() const {
    std::ostringstream stream;
    stream << scheme_ << "://" << (user_.empty() ? "<default>" : user_) << "@"
           << (host_.empty() ? "<missing-host>" : host_) << ":" << port_ << "/"
           << (database_.empty() ? "<missing-db>" : database_);
    if (!ssl_mode_.empty()) {
        stream << "?sslmode=" << ssl_mode_;
    }

    return stream.str();
}

std::string PostgresConnectionInfo::trim_quotes(std::string value) {
    if (value.size() >= 2) {
        const char first = value.front();
        const char last = value.back();
        if ((first == '\'' && last == '\'') || (first == '"' && last == '"')) {
            return value.substr(1, value.size() - 2);
        }
    }

    return value;
}
