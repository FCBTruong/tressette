# Tressette Server - C++

This C++ server replaces the old Python server to improve performance and scalability.

The networking layer uses:

- **Boost.Asio** for asynchronous networking and low-level I/O
- **Boost.Beast** for WebSocket support
- **Protocol Buffers 3.20.3** for packet serialization

The server currently uses asynchronous I/O on a single `io_context` thread. However, the logic layer is still designed to handle multithreaded concurrency by using serialization with `strand`, while shared state accessed across threads should be protected with a `mutex` where necessary.

Rule of thumb:

- `strand` → serialize async handlers
- `mutex` → protect shared memory/data across threads

## Flow Overview

![Network Flow](docs/NetworkGame.drawio.svg)

## Add Your Own Game Mode

This project is built for scalable game applications, so you can easily modify it and create your own game mode. The networking, session management, data serialization, and common user actions such as joining rooms, matchmaking, and leaving are already handled.

![Match Diagram](docs/Matches.svg)

You can create your own match by inheriting from the `IMatch` class.
This class provides the following functions:

- User join
- On receive packet: handles packets requested from the client when the player is in a room
- User disconnected
- User reconnect
- Destroy match

It also provides a loop function that is called every 0.5 seconds, although you can customize it as needed. You can use the `Tressette` mode as an example.

MatchRegistry plays a manageable role. It manages the lifecycle of a match, but it requires the match to report its state back to it.

## How to Deploy on a Production Server

You can deploy on both Windows and Linux, but Linux is recommended because it is more cost-effective and generally provides better performance.

You can build the project with Docker, as a Dockerfile is already provided, or you can use the Linux binary directly.

### Build the Binary on Linux

- Move the project to a Linux environment (for example, use a VM on Windows or a CI/CD pipeline)
- Go to the project directory:

```bash
cd ~/workspace/server_cpp
````

* Build the project:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target tressette_server -j"$(nproc)"
```

### Test on Linux

```bash
cd ~/workspace/server_cpp/build
./tressette_server
```

After building successfully, you need a server instance, such as an AWS EC2 instance.

SSH into the server and upload your `build` output to it.

### Run as a systemd Service

Create a `systemd` service to make sure the server restarts automatically if it fails:

```bash
sudo tee /etc/systemd/system/tressette.service >/dev/null <<'EOF'
[Unit]
Description=Tressette C++ Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/tressette
ExecStart=/home/ubuntu/tressette/tressette_server
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tressette
sudo systemctl start tressette
```

## Let's Start

You can download this project and follow the instructions below to set up local development. This project will be exposed on port `8000`, so make sure that port is available.

This project is developed primarily on **Windows**, so Windows is the recommended environment.

### Requirements

* Visual Studio 2022 with C++ toolchain
* CMake
* Git
* vcpkg
* Boost.Beast / Boost.Asio
* Protocol Buffers 3.20.3

## Install Dependencies

### 1. Install vcpkg

Clone and bootstrap vcpkg:

```bash
git clone https://github.com/microsoft/vcpkg C:\vcpkg
cd C:\vcpkg
bootstrap-vcpkg.bat
```

### 2. Install Dependencies

```bash
& "C:\vcpkg\vcpkg.exe" install
```

## Build

Configure the project with the vcpkg toolchain:

```bash
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Debug
```

## Run

1. Run the server:

```bash
.\build\Debug\card_server.exe
```

2. Run the test client:

```bash
.\build\Debug\test_client.exe
```

## Protocol Buffers Setup

Take a look at `proto/packet.proto`. This is where packet structures are defined.

If you want to define messages exchanged between the client and server, you need to update this file. It allows you to generate protocol code from `proto/packet.proto`.

This is the serialization method used for communication between the client and server. In this project, Protocol Buffers is used to generate packet formats. Packets are serialized and sent in binary form.

Go to the `cpp` folder:

```bash
cd cpp
```

### Install protoc

```bash
git clone --branch v3.20.3 --depth 1 https://github.com/protocolbuffers/protobuf.git protobuf-3.20.3
```

### Generate Packet Code

Configure your `.proto` files and the destination output path, then run:

```bash
gen_proto.sh
```

## Rebuilding protobuf

If you need to rebuild the protobuf library, see:

`docs/build-protobuf-3.20.3.md`

