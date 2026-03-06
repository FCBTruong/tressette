#include <asio.hpp>
#include <array>
#include <iostream>
#include <string>
#include <vector>

#include "packet.pb.h"
#include "net/cmd.hpp"
#include "net/packet_framing.hpp"

using asio::ip::tcp;

static std::vector<uint8_t> to_bytes(const std::string& s) {
    return std::vector<uint8_t>(s.begin(), s.end());
}

int main() {
    try {
        asio::io_context io;

        tcp::socket socket(io);
        socket.connect(tcp::endpoint(asio::ip::make_address("127.0.0.1"), 8000));

        std::cout << "Connected to server\n";

        Packet ping_packet;
        ping_packet.set_cmd_id(Cmd::PING);

        std::string raw = ping_packet.SerializeAsString();
        auto framed = frame_message(raw);
        asio::write(socket, asio::buffer(framed));

        std::cout << "Sent Ping packet\n";
        
        // Read PING response
        std::array<uint8_t, 4> header_buf{};
        asio::read(socket, asio::buffer(header_buf));

        uint32_t payload_size = 0;
        if (!parse_size_header(header_buf.data(), payload_size)) {
            std::cerr << "Failed to parse size header\n";
            return 1;
        }

        if (payload_size == 0 || payload_size > 8 * 1024) {
            std::cerr << "Invalid payload size: " << payload_size << '\n';
            return 1;
        }
        std::vector<uint8_t> body_buf(payload_size);
        asio::read(socket, asio::buffer(body_buf));

        Packet ping_reply;
        if (!ping_reply.ParseFromArray(body_buf.data(), static_cast<int>(body_buf.size()))) {
            std::cerr << "Failed to parse Ping reply Packet\n";
            return 1;
        }

        std::cout << "Received Ping reply:\n";
        std::cout << "  cmd_id = " << ping_reply.cmd_id() << '\n';
        std::cout << "  token = " << ping_reply.token() << '\n';
        std::cout << "  payload_size = " << ping_reply.payload().size() << '\n';

        // Parse payload as PingPong
        PingPong pong;
        if (pong.ParseFromString(ping_reply.payload())) {
            std::cout << "  payload parsed as PingPong\n";
        } else {
            std::cout << "  payload is not valid PingPong\n";
        }

        // Send packet LOGIN

        // 1. Create Login message
        Login login;
        login.set_type(1);
        login.set_token("abc123");
        login.set_device_model("PC");
        login.set_platform("windows");
        login.set_device_country("VN");
        login.set_app_version_code(100);

        // 2. Serialize Login message to string
        std::string login_bytes;
        if (!login.SerializeToString(&login_bytes)) {
            throw std::runtime_error("Failed to serialize Login");
        }

        // 3. Create Packet with LOGIN command
        Packet packet;
        packet.set_token("session_token_here");
        packet.set_cmd_id(Cmd::LOGIN);
        packet.set_payload(login_bytes);

        // 4. Serialize Packet to bytes
        std::string packet_bytes;
        if (!packet.SerializeToString(&packet_bytes)) {
            throw std::runtime_error("Failed to serialize Packet");
        }

        // 5. Send Packet bytes to server
        auto framed_packet = frame_message(packet_bytes);
        asio::write(socket, asio::buffer(framed_packet));
        std::cout << "Sent Login packet\n";

        socket.close();
    } catch (const std::exception& e) {
        std::cerr << "Client error: " << e.what() << '\n';
        return 1;
    }

    return 0;
}