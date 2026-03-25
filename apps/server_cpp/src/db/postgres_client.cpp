#include "db/postgres_client.hpp"

#include <pqxx/pqxx>

#include <stdexcept>
#include <iostream>

namespace {
constexpr unsigned int kPostgresBoolOid = 16;
constexpr unsigned int kPostgresInt8Oid = 20;
constexpr unsigned int kPostgresInt2Oid = 21;
constexpr unsigned int kPostgresInt4Oid = 23;
constexpr unsigned int kPostgresFloat4Oid = 700;
constexpr unsigned int kPostgresFloat8Oid = 701;
constexpr unsigned int kPostgresNumericOid = 1700;

pqxx::params build_params(const std::vector<DbValue>& params) {
    pqxx::params pq_params;
    pq_params.reserve(params.size());

    for (const DbValue& value : params) {
        const DbValue::Storage& storage = value.storage();
        if (std::holds_alternative<std::nullptr_t>(storage)) {
            pq_params.append();
        } else if (const bool* bool_value = std::get_if<bool>(&storage)) {
            pq_params.append(*bool_value);
        } else if (const std::int32_t* int32_value = std::get_if<std::int32_t>(&storage)) {
            pq_params.append(*int32_value);
        } else if (const std::int64_t* int64_value = std::get_if<std::int64_t>(&storage)) {
            pq_params.append(*int64_value);
        } else if (const double* double_value = std::get_if<double>(&storage)) {
            pq_params.append(*double_value);
        } else if (const std::string* string_value = std::get_if<std::string>(&storage)) {
            pq_params.append(*string_value);
        } else {
            throw std::runtime_error("Unsupported DbValue type");
        }
    }

    return pq_params;
}

DbValue field_to_db_value(const pqxx::field& field) {
    if (field.is_null()) {
        return DbValue();
    }

    switch (field.type()) {
    case kPostgresBoolOid:
        return DbValue(field.as<bool>());
    case kPostgresInt2Oid:
    case kPostgresInt4Oid:
        return DbValue(field.as<std::int32_t>());
    case kPostgresInt8Oid:
        return DbValue(field.as<std::int64_t>());
    case kPostgresFloat4Oid:
    case kPostgresFloat8Oid:
    case kPostgresNumericOid:
        return DbValue(field.as<double>());
    default:
        return DbValue(field.as<std::string>());
    }
}
}  // namespace

PostgresClient::PostgresClient(std::string connection_string)
    : connection_info_(PostgresConnectionInfo::from_connection_string(std::move(connection_string))) 
{
    std::cout << "PostgresClient initialized with connection string: " << connection_info_.summary() << '\n';
}

bool PostgresClient::is_configured() const {
    return !connection_info_.connection_string().empty();
}

bool PostgresClient::connect() {
    connected_ = false;
    last_error_.clear();
    connection_.reset();

    if (!is_configured()) {
        last_error_ = "DB_URL is empty";
        return false;
    }

    if (!connection_info_.valid()) {
        last_error_ = "Invalid PostgreSQL connection string: " + connection_info_.summary();
        return false;
    }

    try {
        connection_ = std::make_unique<pqxx::connection>(connection_info_.connection_string());
        connected_ = connection_->is_open();
        if (!connected_) {
            last_error_ = "libpqxx connection was created but not opened";
            connection_.reset();
        }

        return connected_;
    } catch (const std::exception& e) {
        last_error_ = e.what();
        connection_.reset();
        return false;
    }
}

bool PostgresClient::is_connected() const {
    return connected_;
}

std::string PostgresClient::last_error() const {
    return last_error_;
}

DbResult PostgresClient::execute(std::string_view sql, const std::vector<DbValue>& params) {
    if (!connected_ || !connection_) {
        throw std::runtime_error("PostgresClient::execute called before connect()");
    }

    try {
        pqxx::work tx(*connection_);
        pqxx::result result = tx.exec(sql, build_params(params));
        tx.commit();
        return to_db_result(result);
    } catch (const std::exception& e) {
        last_error_ = e.what();
        throw;
    }
}

DbResult PostgresClient::to_db_result(const pqxx::result& result) const {
    DbResult::Storage rows;
    rows.reserve(result.size());

    for (const pqxx::row& result_row : result) {
        DbRow row;
        for (const pqxx::field& field : result_row) {
            row.set(field.name(), field_to_db_value(field));
        }
        rows.push_back(std::move(row));
    }

    return DbResult(std::move(rows));
}
