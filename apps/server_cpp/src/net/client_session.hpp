#pragma once

#include <asio.hpp>
#include <array>
#include <cstdint>
#include <deque>
#include <memory>
#include <vector>

#include "packet.pb.h"

using asio::ip::tcp;

class Server;

class ClientSession : public std::enable_shared_from_this<ClientSession> {
public:
    ClientSession(tcp::socket socket, uint64_t session_id, Server& server);

    void start();
    void send(const Packet& packet);
    void close();

    uint64_t session_id() const { return session_id_; }

private:
    void read_header();
    void read_body(uint32_t payload_size);
    void do_write();

private:
    tcp::socket socket_;
    uint64_t session_id_;
    Server& server_;

    std::array<uint8_t, 4> header_buf_{};
    std::vector<uint8_t> body_buf_;

    std::deque<std::vector<uint8_t>> write_queue_;
    bool closed_ = false;
};