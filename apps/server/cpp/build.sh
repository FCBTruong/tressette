cmake -S . -B build
cmake --build build --config Debug

# Run the server
.\build\Debug\card_server.exe

# Run the client test
.\build\Debug\test_client.exe