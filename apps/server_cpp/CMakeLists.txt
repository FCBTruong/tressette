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

add_executable(tressette_server
    ${TRESSETTE_SERVER_SOURCES}
    proto/packet.pb.cpp
)

add_executable(test_client
    src/test_client.cpp
    proto/packet.pb.cpp
)

target_include_directories(tressette_server PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/proto
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_include_directories(test_client PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/proto
    ${CMAKE_CURRENT_SOURCE_DIR}/src
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
    find_package(Protobuf REQUIRED)

    target_include_directories(tressette_server PRIVATE
        ${Protobuf_INCLUDE_DIRS}
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/protobuf/include
    )

    target_include_directories(test_client PRIVATE
        ${Protobuf_INCLUDE_DIRS}
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/protobuf/include
    )

    target_link_libraries(tressette_server PRIVATE
        ${Protobuf_LIBRARIES}
        pthread
    )

    target_link_libraries(test_client PRIVATE
        ${Protobuf_LIBRARIES}
        pthread
    )
endif()

install(TARGETS tressette_server
    RUNTIME DESTINATION bin
)