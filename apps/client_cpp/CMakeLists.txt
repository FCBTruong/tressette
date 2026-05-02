cmake_minimum_required(VERSION 3.24)

project(TressetteOfflineCpp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

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

set(SDL3_TTF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/external/SDL3_ttf-3.2.2")
if(NOT TARGET SDL3_ttf::SDL3_ttf)
    add_library(SDL3_ttf::SDL3_ttf SHARED IMPORTED)
    set_target_properties(SDL3_ttf::SDL3_ttf PROPERTIES
        IMPORTED_IMPLIB "${SDL3_TTF_ROOT}/lib/x64/SDL3_ttf.lib"
        IMPORTED_LOCATION "${SDL3_TTF_ROOT}/lib/x64/SDL3_ttf.dll"
        INTERFACE_INCLUDE_DIRECTORIES "${SDL3_TTF_ROOT}/include"
    )
endif()

add_executable(tressette_offline
    src/main.cpp
    src/loading_scene.cpp
    src/lobby/game_portal.cpp
    src/games/memory_cards/memory_cards_game.cpp
    src/games/tressette/tressette_game.cpp
)

target_link_libraries(tressette_offline PRIVATE SDL3::SDL3)
target_link_libraries(tressette_offline PRIVATE SDL3_image::SDL3_image)
target_link_libraries(tressette_offline PRIVATE SDL3_ttf::SDL3_ttf)

add_custom_command(TARGET tressette_offline POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_RUNTIME_DLLS:tressette_offline>
        $<TARGET_FILE_DIR:tressette_offline>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/external/SDL3_ttf-3.2.2/lib/x64/SDL3_ttf.dll"
        $<TARGET_FILE_DIR:tressette_offline>
    COMMAND_EXPAND_LISTS
)

if(MSVC)
    target_compile_options(tressette_offline PRIVATE /W4 /permissive-)
else()
    target_compile_options(tressette_offline PRIVATE -Wall -Wextra -Wpedantic)
endif()
