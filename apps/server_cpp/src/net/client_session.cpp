#include "client_session.hpp"

#include <iostream>
#include <string>

#include "packet_framing.hpp"
#include "router.hpp"
#include "server.hpp"
#include "packet.pb.h"

static constexpr uint32_t kMaxPayloadSize = 8 * 1024;

ClientSession::ClientSession(tcp::socket socket, uint64_t session_id, Server& server)
    : socket_(std::move(socket)),
      session_id_(session_id),
      server_(server) {}

void ClientSession::start() {
    read_header();
}

void ClientSession::read_header() {
    auto self = shared_from_this();

    asio::async_read(
        socket_,
        asio::buffer(header_buf_),
        [this, self](std::error_code ec, std::size_t /*length*/) {
            if (ec) {
                close();
                return;
            }

            uint32_t payload_size = 0;
            if (!parse_size_header(header_buf_.data(), payload_size)) {
                close();
                return;
            }

            if (payload_size == 0 || payload_size > kMaxPayloadSize) {
                std::cerr << "Invalid payload size from session " << session_id_ << '\n';
                close();
                return;
            }

            read_body(payload_size);
        }
    );
}

void ClientSession::read_body(uint32_t payload_size) {
    auto self = shared_from_this();

    body_buf_.resize(payload_size);

    asio::async_read(
        socket_,
        asio::buffer(body_buf_),
        [this, self](std::error_code ec, std::size_t /*length*/) {
            if (ec) {
                close();
                return;
            }

            Packet packet;
            if (!packet.ParseFromArray(body_buf_.data(), static_cast<int>(body_buf_.size()))) {
                std::cerr << "Failed to parse protobuf Packet from session " << session_id_ << '\n';
                close();
                return;
            }

            server_.router().handle(self, packet);

            read_header();
        }
    );
}

void ClientSession::send(const Packet& packet) {
    std::string packet_bytes;
    if (!packet.SerializeToString(&packet_bytes)) {
        std::cerr << "Failed to serialize protobuf Packet for session " << session_id_ << '\n';
        return;
    }

    auto data = frame_message(packet_bytes);
    const bool write_in_progress = !write_queue_.empty();

    write_queue_.push_back(std::move(data));

    if (!write_in_progress) {
        do_write();
    }
}

void ClientSession::do_write() {
    auto self = shared_from_this();

    asio::async_write(
        socket_,
        asio::buffer(write_queue_.front()),
        [this, self](std::error_code ec, std::size_t /*length*/) {
            if (ec) {
                close();
                return;
            }

            write_queue_.pop_front();

            if (!write_queue_.empty()) {
                do_write();
            }
        }
    );
}

void ClientSession::close() {
    if (closed_) {
        return;
    }
    closed_ = true;

    std::error_code ignored_ec;
    socket_.close(ignored_ec);
    server_.remove_session(session_id_);
}