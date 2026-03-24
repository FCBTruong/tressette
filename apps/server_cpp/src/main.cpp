#include "net/server.hpp"
#include <iostream>

int main() {
    try {
        asio::io_context io;
        Server server(io);
        server.start();
        io.run();
    } catch (const std::exception& e) {
        std::cerr << "Fatal error: " << e.what() << '\n';
    }

    return 0;
}