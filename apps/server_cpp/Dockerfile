FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libboost-dev \
    nlohmann-json3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN cmake -S . -B /tmp/cmake-build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build /tmp/cmake-build --target tressette_server -j"$(nproc)" \
    && cmake --install /tmp/cmake-build --prefix /app/dist

FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libstdc++6 \
    libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/dist /app

CMD ["/app/bin/tressette_server"]