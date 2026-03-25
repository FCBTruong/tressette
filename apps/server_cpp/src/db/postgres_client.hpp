#pragma once

#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "db/db_client.hpp"
#include "db/postgres_connection_info.hpp"

namespace pqxx {
class connection;
class result;
}

class PostgresClient : public DbClient {
public:
    explicit PostgresClient(std::string connection_string);

    bool is_configured() const override;
    bool connect() override;
    bool is_connected() const override;
    std::string last_error() const override;
    DbResult execute(std::string_view sql, const std::vector<DbValue>& params = {}) override;

    const PostgresConnectionInfo& connection_info() const { return connection_info_; }

private:
    DbResult to_db_result(const pqxx::result& result) const;

    PostgresConnectionInfo connection_info_;
    std::unique_ptr<pqxx::connection> connection_;
    bool connected_ = false;
    std::string last_error_;
};
