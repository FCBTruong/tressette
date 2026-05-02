cmake_minimum_required(VERSION 3.22)

project(TressetteOfflineCpp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(ANDROID)
    add_link_options(
        "LINKER:-z,max-page-size=16384"
        "LINKER:-z,common-page-size=16384"
    )
endif()

include(FetchContent)

set(SDL_SHARED ON CACHE BOOL "" FORCE)
set(SDL_STATIC OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
    SDL3
    URL https://github.com/libsdl-org/SDL/releases/download/release-3.2.10/SDL3-3.2.10.tar.gz
)
FetchContent_MakeAvailable(SDL3)

set(SDLIMAGE_AVIF OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_BMP ON CACHE BOOL "" FORCE)
set(SDLIMAGE_GIF OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_JPG OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_JXL OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_LBM OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_PCX OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_PNG ON CACHE BOOL "" FORCE)
set(SDLIMAGE_PNM OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_QOI OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_SVG OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_TGA OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_TIF OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_WEBP OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_XCF OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_XPM OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_XV OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_SAMPLES OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_TESTS OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_DEPS_SHARED OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
    SDL3_image
    URL https://github.com/libsdl-org/SDL_image/releases/download/release-3.2.4/SDL3_image-3.2.4.tar.gz
)
FetchContent_MakeAvailable(SDL3_image)

set(TRESSETTE_SOURCES
    src/main.cpp
    src/loading_scene.cpp
    src/lobby/game_portal.cpp
    src/games/farm/farm_game.cpp
    src/games/flappy_bird/flappy_bird_game.cpp
    src/games/scopa/scopa_game.cpp
    src/games/tressette/tressette_game.cpp
)

list(APPEND TRESSETTE_SOURCES src/games/memory_cards/memory_cards_game.cpp)

if(ANDROID)
    add_library(main SHARED ${TRESSETTE_SOURCES})
    set(TRESSETTE_TARGET main)
else()
    add_executable(tressette_offline ${TRESSETTE_SOURCES})
    set(TRESSETTE_TARGET tressette_offline)
endif()

target_link_libraries(${TRESSETTE_TARGET} PRIVATE SDL3::SDL3)
target_link_libraries(${TRESSETTE_TARGET} PRIVATE SDL3_image::SDL3_image)

if(NOT ANDROID)
    add_custom_command(TARGET ${TRESSETTE_TARGET} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_RUNTIME_DLLS:${TRESSETTE_TARGET}>
            $<TARGET_FILE_DIR:${TRESSETTE_TARGET}>
        COMMAND_EXPAND_LISTS
    )
endif()

if(MSVC)
    target_compile_options(${TRESSETTE_TARGET} PRIVATE /W4 /permissive-)
else()
    target_compile_options(${TRESSETTE_TARGET} PRIVATE -Wall -Wextra -Wpedantic)
endif()
