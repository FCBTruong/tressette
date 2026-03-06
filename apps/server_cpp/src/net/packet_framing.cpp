#include "packet_framing.hpp"

#include <algorithm>

std::vector<uint8_t> frame_message(const std::string& body) {
    const uint32_t payload_size = static_cast<uint32_t>(body.size());

    std::vector<uint8_t> out(4 + payload_size);

    out[0] = static_cast<uint8_t>((payload_size >> 24) & 0xFF);
    out[1] = static_cast<uint8_t>((payload_size >> 16) & 0xFF);
    out[2] = static_cast<uint8_t>((payload_size >> 8) & 0xFF);
    out[3] = static_cast<uint8_t>(payload_size & 0xFF);

    std::copy(body.begin(), body.end(), out.begin() + 4);
    return out;
}

bool parse_size_header(const uint8_t* data, uint32_t& payload_size) {
    payload_size =
        (static_cast<uint32_t>(data[0]) << 24) |
        (static_cast<uint32_t>(data[1]) << 16) |
        (static_cast<uint32_t>(data[2]) << 8) |
        static_cast<uint32_t>(data[3]);

    return true;
}