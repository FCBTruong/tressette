
# Tressette Server - C++

The C++ server replaces the old Python server to improve performance and scalability.

The networking layer now uses:

- **Boost.Asio** for asynchronous networking and low-level I/O
- **Boost.Beast** for WebSocket support
- **Protocol Buffers 3.20.3** for packet serialization

The server currently uses asynchronous I/O on a single `io_context` thread, so handlers do not run concurrently. Before enabling multi-threaded execution, per-session handler execution should be serialized with `strand`, and shared state accessed across threads should be protected with `mutex` where needed.

Rule of thumb:

* `strand` → serialize async handlers
* `mutex` → protect shared memory/data across threads

## Flow Overview

![Network Flow](docs/NetworkGame.drawio.svg)

## Recommended Environment

This project is developed primarily on **Windows**, so Windows is the recommended environment.

## Requirements

- Visual Studio 2022 with C++ toolchain
- CMake
- Git
- vcpkg
- Boost.Beast / Boost.Asio
- Protocol Buffers 3.20.3

## Install Dependencies

### 1. Install vcpkg

Clone and bootstrap vcpkg:

```bash
git clone https://github.com/microsoft/vcpkg C:\vcpkg
cd C:\vcpkg
bootstrap-vcpkg.bat
````

### 2. Install Boost.Beast

```bash
.\vcpkg install boost-beast
```

`boost-beast` will pull the Boost dependencies needed for Beast and Asio.

### 3. Install Dependencies
``` bash
.\vcpkg install nlohmann-json
```

## Build

Configure the project with the vcpkg toolchain:

```bash
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Debug
```

If you want a Release build:

```bash
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Release
```

## Run

### Run the server

```bash
.\build\Debug\card_server.exe
```

### Run the test client

```bash
.\build\Debug\test_client.exe
```

For Release:

```bash
.\build\Release\card_server.exe
.\build\Release\test_client.exe
```

## Protocol Buffers Setup

Go to the `cpp` folder:

```bash
cd cpp
```

### Install protoc

```bash
git clone --branch v3.20.3 --depth 1 https://github.com/protocolbuffers/protobuf.git protobuf-3.20.3
```

### Generate packet code

Configure your `.proto` files and destination output path, then run:

```bash
gen_proto.sh
```

## Rebuilding protobuf

If you need to rebuild the protobuf library, see:

`docs/build-protobuf-3.20.3.md`

## Notes

* The old standalone Asio setup has been replaced by **Boost.Asio**.
* WebSocket support is implemented with **Boost.Beast**.
* When building with CMake, always pass the vcpkg toolchain file.
* If IntelliSense does not detect Boost headers immediately, reconfigure the CMake project after installing dependencies.

