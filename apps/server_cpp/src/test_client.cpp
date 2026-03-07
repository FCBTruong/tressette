#include <boost/asio.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/websocket.hpp>
#include <iostream>
#include <string>

#include "packet.pb.h"
#include "net/cmd.hpp"

namespace asio = boost::asio;
namespace beast = boost::beast;
namespace websocket = boost::beast::websocket;
using tcp = asio::ip::tcp;

int main() {
    try {
        asio::io_context io;

        tcp::resolver resolver(io);
        auto const results = resolver.resolve("127.0.0.1", "8000");

        websocket::stream<tcp::socket> ws(io);

        asio::connect(ws.next_layer(), results.begin(), results.end());

        ws.handshake("127.0.0.1", "/");

        std::cout << "Connected to WebSocket server\n";

        ws.binary(true);

        // Send Ping packet
        Packet ping_packet;
        ping_packet.set_cmd_id(Cmd::PING_PONG);

        std::string ping_bytes;
        if (!ping_packet.SerializeToString(&ping_bytes)) {
            throw std::runtime_error("Failed to serialize Ping packet");
        }

        ws.write(asio::buffer(ping_bytes));
        std::cout << "Sent Ping packet\n";

        // Read Ping response
        beast::flat_buffer buffer;
        ws.read(buffer);

        std::string response = beast::buffers_to_string(buffer.data());

        Packet ping_reply;
        if (!ping_reply.ParseFromArray(response.data(), static_cast<int>(response.size()))) {
            std::cerr << "Failed to parse Ping reply Packet\n";
            return 1;
        }

        std::cout << "Received Ping reply:\n";
        std::cout << "  cmd_id = " << ping_reply.cmd_id() << '\n';
        std::cout << "  token = " << ping_reply.token() << '\n';
        std::cout << "  payload_size = " << ping_reply.payload().size() << '\n';

        PingPong pong;
        if (pong.ParseFromString(ping_reply.payload())) {
            std::cout << "  payload parsed as PingPong\n";
        } else {
            std::cout << "  payload is not valid PingPong\n";
        }

        // Send Login packet
        Login login;
        login.set_type(1);
        login.set_token("abc123");
        login.set_device_model("PC");
        login.set_platform("windows");
        login.set_device_country("VN");
        login.set_app_version_code(100);

        std::string login_bytes;
        if (!login.SerializeToString(&login_bytes)) {
            throw std::runtime_error("Failed to serialize Login");
        }

        Packet packet;
        packet.set_token("session_token_here");
        packet.set_cmd_id(Cmd::LOGIN);
        packet.set_payload(login_bytes);

        std::string packet_bytes;
        if (!packet.SerializeToString(&packet_bytes)) {
            throw std::runtime_error("Failed to serialize Packet");
        }

        ws.write(asio::buffer(packet_bytes));
        std::cout << "Sent Login packet\n";

        ws.close(websocket::close_code::normal);
    } catch (const std::exception& e) {
        std::cerr << "Client error: " << e.what() << '\n';
        return 1;
    }

    return 0;
}