#pragma once

#include <cstdint>
#include <string>
#include <vector>

std::vector<uint8_t> frame_message(const std::string& body);
bool parse_size_header(const uint8_t* data, uint32_t& payload_size);