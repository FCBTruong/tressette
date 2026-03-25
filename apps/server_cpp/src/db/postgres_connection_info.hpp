#pragma once

#include <cstdint>
#include <string>

class PostgresConnectionInfo {
public:
    static PostgresConnectionInfo from_connection_string(std::string connection_string);

    bool valid() const;
    std::string summary() const;

    const std::string& connection_string() const { return connection_string_; }
    const std::string& scheme() const { return scheme_; }
    const std::string& user() const { return user_; }
    const std::string& password() const { return password_; }
    const std::string& host() const { return host_; }
    std::uint16_t port() const { return port_; }
    const std::string& database() const { return database_; }
    const std::string& ssl_mode() const { return ssl_mode_; }

private:
    static std::string trim_quotes(std::string value);

private:
    std::string connection_string_;
    std::string scheme_;
    std::string user_;
    std::string password_;
    std::string host_;
    std::uint16_t port_ = 5432;
    std::string database_;
    std::string ssl_mode_;
};
