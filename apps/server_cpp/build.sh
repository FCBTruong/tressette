cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Debug

# Run the server
.\build\Debug\card_server.exe

# Run the client test
.\build\Debug\test_client.exe


# Build release server
docker build --no-cache -t tressette_server .
docker run --rm -p 8080:8080 tressette_server