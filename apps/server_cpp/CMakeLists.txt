cmake_minimum_required(VERSION 3.20)
project(card_server LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(ASIO_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/asio/include)
set(PROTOBUF_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/protobuf/include)
set(PROTOBUF_LIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/protobuf/lib/Win64)

add_executable(card_server
    src/main.cpp
    src/net/server.cpp
    src/net/listener.cpp
    src/net/client_session.cpp
    src/net/router.cpp
    src/net/packet_framing.cpp
    proto/packet.pb.cpp
)

add_executable(test_client
    src/test_client.cpp
    src/net/packet_framing.cpp
    proto/packet.pb.cpp
)

target_include_directories(card_server PRIVATE
    ${ASIO_INCLUDE_DIR}
    ${PROTOBUF_INCLUDE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/proto
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/net
)

target_include_directories(test_client PRIVATE
    ${ASIO_INCLUDE_DIR}
    ${PROTOBUF_INCLUDE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/proto
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/net
)

target_link_directories(card_server PRIVATE
    ${PROTOBUF_LIB_DIR}
)

target_link_directories(test_client PRIVATE
    ${PROTOBUF_LIB_DIR}
)

target_compile_definitions(card_server PRIVATE
    ASIO_STANDALONE
    _WIN32_WINNT=0x0A00
)

target_compile_definitions(test_client PRIVATE
    ASIO_STANDALONE
    _WIN32_WINNT=0x0A00
)

target_link_libraries(card_server PRIVATE
    ws2_32
)

target_link_libraries(test_client PRIVATE
    ws2_32
)

if(MSVC)
    target_link_libraries(card_server PRIVATE debug libprotobufd optimized libprotobuf)
    target_link_libraries(test_client PRIVATE debug libprotobufd optimized libprotobuf)
else()
    target_link_libraries(card_server PRIVATE libprotobuf)
    target_link_libraries(test_client PRIVATE libprotobuf)
endif()