#include "net/server.hpp"
#include <iostream>

int main() {
    try {
        asio::io_context io;

        Server server(io, 8000);
        server.start();

        std::cout << "Server started on port 8000\n";

        io.run();
    } catch (const std::exception& e) {
        std::cerr << "Fatal error: " << e.what() << '\n';
    }

    return 0;
}