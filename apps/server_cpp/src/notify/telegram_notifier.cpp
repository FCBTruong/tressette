#include "notify/telegram_notifier.hpp"

#include <boost/asio/connect.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/asio/ssl/context.hpp>
#include <boost/asio/ssl/error.hpp>
#include <boost/asio/ssl/host_name_verification.hpp>
#include <boost/asio/ssl/stream.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/ssl.hpp>
#include <boost/beast/version.hpp>
#include <boost/system/error_code.hpp>

#include <openssl/err.h>
#include <openssl/ssl.h>

#include <cctype>
#include <iomanip>
#include <sstream>
#include <utility>

namespace asio = boost::asio;
namespace beast = boost::beast;
namespace http = beast::http;
namespace ssl = asio::ssl;
using tcp = asio::ip::tcp;

TelegramNotifier::TelegramNotifier(std::string bot_token, std::string chat_id, bool skip_tls_verify)
    : bot_token_(std::move(bot_token)),
      chat_id_(std::move(chat_id)),
      skip_tls_verify_(skip_tls_verify) {}

bool TelegramNotifier::enabled() const {
    return !bot_token_.empty() && !chat_id_.empty();
}

bool TelegramNotifier::send_message(const std::string& text, std::string* error_message) const {
    if (!enabled()) {
        if (error_message) {
            *error_message = "Telegram notifier is disabled";
        }
        return false;
    }

    try {
        asio::io_context io;
        ssl::context ssl_context(ssl::context::tls_client);
        ssl_context.set_default_verify_paths();

        tcp::resolver resolver(io);
        beast::ssl_stream<beast::tcp_stream> stream(io, ssl_context);

        const std::string host = "api.telegram.org";
        const std::string port = "443";
        const std::string target = "/bot" + bot_token_ + "/sendMessage";
        const std::string body =
            "chat_id=" + url_encode(chat_id_) +
            "&text=" + url_encode(text);

        if (skip_tls_verify_) {
            stream.set_verify_mode(ssl::verify_none);
        } else {
            stream.set_verify_mode(ssl::verify_peer);
            stream.set_verify_callback(ssl::host_name_verification(host));
        }

        if (!SSL_set_tlsext_host_name(stream.native_handle(), host.c_str())) {
            throw beast::system_error(
                beast::error_code(static_cast<int>(::ERR_get_error()), asio::error::get_ssl_category()));
        }

        auto endpoints = resolver.resolve(host, port);
        beast::get_lowest_layer(stream).connect(endpoints);
        stream.handshake(ssl::stream_base::client);

        http::request<http::string_body> request(http::verb::post, target, 11);
        request.set(http::field::host, host);
        request.set(http::field::user_agent, BOOST_BEAST_VERSION_STRING);
        request.set(http::field::content_type, "application/x-www-form-urlencoded");
        request.body() = body;
        request.prepare_payload();

        http::write(stream, request);

        beast::flat_buffer buffer;
        http::response<http::string_body> response;
        http::read(stream, buffer, response);

        boost::system::error_code ec;
        stream.shutdown(ec);
        if (ec == asio::error::eof || ec == ssl::error::stream_truncated) {
            ec = {};
        }
        if (ec) {
            throw beast::system_error(ec);
        }

        if (response.result() != http::status::ok) {
            if (error_message) {
                *error_message = "Telegram API returned " + std::to_string(response.result_int()) + ": " + response.body();
            }
            return false;
        }

        return true;
    } catch (const std::exception& e) {
        if (error_message) {
            *error_message = e.what();
        }
        return false;
    }
}

std::string TelegramNotifier::url_encode(const std::string& value) {
    std::ostringstream encoded;
    encoded << std::uppercase << std::hex;

    for (unsigned char ch : value) {
        if (std::isalnum(ch) || ch == '-' || ch == '_' || ch == '.' || ch == '~') {
            encoded << static_cast<char>(ch);
        } else if (ch == ' ') {
            encoded << '+';
        } else {
            encoded << '%' << std::setw(2) << std::setfill('0') << static_cast<int>(ch);
        }
    }

    return encoded.str();
}
