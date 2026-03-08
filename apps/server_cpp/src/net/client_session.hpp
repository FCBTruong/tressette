#pragma once

#include <boost/asio.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/websocket.hpp>
#include <cstdint>
#include <deque>
#include <memory>
#include <optional>
#include <string>

#include <google/protobuf/message.h>

#include "packet.pb.h"

namespace asio = boost::asio;
namespace beast = boost::beast;
namespace websocket = boost::beast::websocket;
using tcp = asio::ip::tcp;

class Server;

class ClientSession : public std::enable_shared_from_this<ClientSession> {
public:
    ClientSession(tcp::socket socket, uint64_t session_id, Server& server);

    void start();
    void send(const packet::Packet& packet);
    bool send_packet(int cmd_id, const google::protobuf::Message& msg);
    void close();

    uint64_t session_id() const;
    std::optional<uint64_t> uid() const;

    void bind_uid(uint64_t uid);
    void clear_uid();

    bool is_authenticated() const;
    void clear_auth();

    const std::string& session_token() const;
    void set_session_token(std::string token);

private:
    void on_accept(beast::error_code ec);
    void do_read();
    void do_write();
    void do_close();

private:
    websocket::stream<beast::tcp_stream> ws_;
    beast::flat_buffer read_buffer_;
    std::deque<std::string> write_queue_;

    uint64_t session_id_ = 0;
    std::optional<uint64_t> uid_;
    std::string session_token_;
    bool closed_ = false;

    Server& server_;
};