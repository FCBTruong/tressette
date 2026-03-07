#include "client_session.hpp"

#include <iostream>
#include <string>
#include <utility>

#include "net/cmd.hpp"
#include "packet.pb.h"
#include "router.hpp"
#include "server.hpp"

static constexpr std::size_t kMaxPayloadSize = 8 * 1024;

ClientSession::ClientSession(tcp::socket socket, uint64_t session_id, Server& server)
    : ws_(std::move(socket)),
      session_id_(session_id),
      server_(server) {}

uint64_t ClientSession::session_id() const {
    return session_id_;
}

std::optional<uint64_t> ClientSession::uid() const {
    return uid_;
}

void ClientSession::bind_uid(uint64_t uid) {
    uid_ = uid;
}

void ClientSession::clear_uid() {
    uid_.reset();
}

bool ClientSession::is_authenticated() const {
    return uid_.has_value() && !session_token_.empty();
}

void ClientSession::clear_auth() {
    uid_.reset();
    session_token_.clear();
}

const std::string& ClientSession::session_token() const {
    return session_token_;
}

void ClientSession::set_session_token(std::string token) {
    session_token_ = std::move(token);
}

void ClientSession::start() {
    auto self = shared_from_this();

    asio::dispatch(
        ws_.get_executor(),
        [this, self]() {
            ws_.set_option(
                websocket::stream_base::timeout::suggested(beast::role_type::server));

            ws_.binary(true);

            ws_.async_accept(
                [this, self](beast::error_code ec) {
                    on_accept(ec);
                });
        });
}

void ClientSession::on_accept(beast::error_code ec) {
    if (ec) {
        std::cerr << "WebSocket accept failed for session " << session_id_
                  << ": " << ec.message() << '\n';
        do_close();
        return;
    }

    std::cout << "WebSocket handshake success, session_id=" << session_id_ << '\n';

    if (!send_packet(Cmd::APP_VERSION, server_.app_config().app_code_version())) {
        std::cerr << "Failed to send APP_VERSION to session "
                  << session_id_ << '\n';
    }

    do_read();
}

void ClientSession::do_read() {
    auto self = shared_from_this();

    ws_.async_read(
        read_buffer_,
        [this, self](beast::error_code ec, std::size_t bytes_transferred) {
            if (ec) {
                if (ec != websocket::error::closed) {
                    std::cerr << "Read error, session " << session_id_
                              << ": " << ec.message() << '\n';
                }
                do_close();
                return;
            }

            if (bytes_transferred == 0 || bytes_transferred > kMaxPayloadSize) {
                std::cerr << "Invalid message size from session "
                          << session_id_ << '\n';
                do_close();
                return;
            }

            auto data = read_buffer_.data();

            Packet packet;
            if (!packet.ParseFromArray(
                    beast::buffers_front(data).data(),
                    static_cast<int>(bytes_transferred))) {
                std::cerr << "Failed to parse protobuf Packet from session "
                          << session_id_ << '\n';
                do_close();
                return;
            }

            read_buffer_.consume(read_buffer_.size());

            server_.router().handle(self, packet);

            if (!closed_) {
                do_read();
            }
        });
}

void ClientSession::send(const Packet& packet) {
    std::string packet_bytes;
    if (!packet.SerializeToString(&packet_bytes)) {
        std::cerr << "Failed to serialize protobuf Packet for session "
                  << session_id_ << '\n';
        return;
    }

    auto self = shared_from_this();

    asio::post(
        ws_.get_executor(),
        [this, self, packet_bytes = std::move(packet_bytes)]() mutable {
            if (closed_) {
                return;
            }

            const bool write_in_progress = !write_queue_.empty();
            write_queue_.push_back(std::move(packet_bytes));

            if (!write_in_progress) {
                do_write();
            }
        });
}

bool ClientSession::send_packet(int cmd_id, const google::protobuf::Message& msg) {
    std::string payload;
    if (!msg.SerializeToString(&payload)) {
        std::cerr << "Failed to serialize payload for session "
                  << session_id_ << ", cmd_id=" << cmd_id << '\n';
        return false;
    }

    Packet packet;
    packet.set_cmd_id(cmd_id);

    if (!session_token_.empty()) {
        packet.set_token(session_token_);
    }

    packet.set_payload(payload);
    send(packet);
    return true;
}

void ClientSession::do_write() {
    auto self = shared_from_this();

    ws_.binary(true);

    ws_.async_write(
        asio::buffer(write_queue_.front()),
        [this, self](beast::error_code ec, std::size_t /*bytes_transferred*/) {
            if (ec) {
                if (ec != websocket::error::closed) {
                    std::cerr << "Write error, session " << session_id_
                              << ": " << ec.message() << '\n';
                }
                do_close();
                return;
            }

            write_queue_.pop_front();

            if (!write_queue_.empty() && !closed_) {
                do_write();
            }
        });
}

void ClientSession::close() {
    auto self = shared_from_this();

    asio::post(
        ws_.get_executor(),
        [this, self]() {
            do_close();
        });
}

void ClientSession::do_close() {
    if (closed_) {
        return;
    }

    closed_ = true;

    auto self = shared_from_this();

    ws_.async_close(
        websocket::close_code::normal,
        [this, self](beast::error_code ec) {
            if (ec && ec != websocket::error::closed) {
                std::cerr << "Close error, session " << session_id_
                          << ": " << ec.message() << '\n';
            }

            server_.remove_session(session_id_);
        });
}