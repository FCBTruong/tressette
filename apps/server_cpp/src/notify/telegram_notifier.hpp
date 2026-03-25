#pragma once

#include <string>

class TelegramNotifier {
public:
    TelegramNotifier(std::string bot_token, std::string chat_id, bool skip_tls_verify);

    bool enabled() const;
    bool send_message(const std::string& text, std::string* error_message = nullptr) const;

private:
    static std::string url_encode(const std::string& value);

private:
    std::string bot_token_;
    std::string chat_id_;
    bool skip_tls_verify_ = false;
};
