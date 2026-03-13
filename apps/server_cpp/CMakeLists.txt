cmake_minimum_required(VERSION 3.20)
project(tressette_server LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

file(GLOB_RECURSE TRESSETTE_SERVER_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
)

list(REMOVE_ITEM TRESSETTE_SERVER_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/test_client.cpp
)

set(PROTO_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/proto/packet.pb.cpp
)

add_executable(tressette_server
    ${TRESSETTE_SERVER_SOURCES}
    ${PROTO_SOURCES}
)

add_executable(test_client
    ${CMAKE_CURRENT_SOURCE_DIR}/src/test_client.cpp
    ${PROTO_SOURCES}
)

add_custom_command(TARGET tressette_server POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_SOURCE_DIR}/config
    $<TARGET_FILE_DIR:tressette_server>/config
)

target_include_directories(tressette_server PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/proto
)

target_include_directories(test_client PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/proto
)

if(WIN32)
    set(PROTOBUF_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/protobuf/include)
    set(PROTOBUF_LIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/protobuf/lib/Win64)
    set(VCPKG_INSTALLED_DIR C:/vcpkg/installed/x64-windows)

    target_include_directories(tressette_server PRIVATE
        ${VCPKG_INSTALLED_DIR}/include
        ${PROTOBUF_INCLUDE_DIR}
    )

    target_include_directories(test_client PRIVATE
        ${VCPKG_INSTALLED_DIR}/include
        ${PROTOBUF_INCLUDE_DIR}
    )

    target_link_directories(tressette_server PRIVATE
        ${PROTOBUF_LIB_DIR}
    )

    target_link_directories(test_client PRIVATE
        ${PROTOBUF_LIB_DIR}
    )

    target_compile_definitions(tressette_server PRIVATE
        _WIN32_WINNT=0x0A00
    )

    target_compile_definitions(test_client PRIVATE
        _WIN32_WINNT=0x0A00
    )

    target_link_libraries(tressette_server PRIVATE
        ws2_32
        debug libprotobufd
        optimized libprotobuf
    )

    target_link_libraries(test_client PRIVATE
        ws2_32
        debug libprotobufd
        optimized libprotobuf
    )
else()
    set(PROTOBUF_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/protobuf/include)
    set(PROTOBUF_LINUX_STATIC_LIB ${CMAKE_CURRENT_SOURCE_DIR}/third_party/protobuf/lib/Linux/libprotobuf.a)

    target_include_directories(tressette_server PRIVATE
        ${PROTOBUF_INCLUDE_DIR}
    )

    target_include_directories(test_client PRIVATE
        ${PROTOBUF_INCLUDE_DIR}
    )

    target_link_libraries(tressette_server PRIVATE
        ${PROTOBUF_LINUX_STATIC_LIB}
        pthread
    )

    target_link_libraries(test_client PRIVATE
        ${PROTOBUF_LINUX_STATIC_LIB}
        pthread
    )
endif()

install(TARGETS tressette_server
    RUNTIME DESTINATION bin
)