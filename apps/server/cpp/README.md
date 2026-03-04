# Tressette Server - C++
The C++ server project replaces the old Python project to improve performance and scalability. It uses Asio as a native library for networking and low-level I/O, enabling asynchronous code.

## Flow Overview
![Network Flow](docs/NetworkGame.drawio.svg)

## Recommended Environment

This project was developed on Windows, so using Windows is recommended.

## Requirements

* C++ native toolchain
* Asio 1.36.0
* CMake
* Protocol Buffers 3.20.3

## Build

```bash
cmake -S . -B build
cmake --build build --config Debug
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
