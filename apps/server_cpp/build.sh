cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Debug

# Run the server
.\build\Debug\card_server.exe

# Run the client test
.\build\Debug\test_client.exe