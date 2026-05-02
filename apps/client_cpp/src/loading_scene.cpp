#include "loading_scene.h"

#include <SDL3/SDL.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <string>

namespace {

constexpr int kBaseWidth = 480;
constexpr int kBaseHeight = 854;
constexpr std::uint64_t kLoadingDurationMs = 260;

void setColor(SDL_Renderer* renderer, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    SDL_SetRenderDrawColor(renderer, r, g, b, a);
}

void fillRect(SDL_Renderer* renderer, const SDL_FRect& rect, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    SDL_RenderFillRect(renderer, &rect);
}

void strokeRect(SDL_Renderer* renderer, const SDL_FRect& rect, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    SDL_RenderRect(renderer, &rect);
}

float debugTextWidth(const std::string& value) {
    return static_cast<float>(value.size()) * 8.0f;
}

float uiTextWidth(const std::string& value, float scale = 1.18f) {
    return debugTextWidth(value) * scale;
}

void uiText(SDL_Renderer* renderer, float x, float y, const std::string& value, float scale = 1.18f) {
    const float invScale = 1.0f / scale;
    std::uint8_t r = 255;
    std::uint8_t g = 255;
    std::uint8_t b = 255;
    std::uint8_t a = 255;
    SDL_GetRenderDrawColor(renderer, &r, &g, &b, &a);
    SDL_SetRenderScale(renderer, scale, scale);
    setColor(renderer, r, g, b, a);
    SDL_RenderDebugText(renderer, x * invScale, y * invScale, value.c_str());
    SDL_SetRenderScale(renderer, 1.0f, 1.0f);
}

void applyWindowState(SDL_Window* window, const AppWindowState& state) {
    SDL_SetWindowSize(window, state.width, state.height);
    if (state.hasPosition) {
        SDL_SetWindowPosition(window, state.posX, state.posY);
    }
    if (state.maximized) {
        SDL_MaximizeWindow(window);
    }
    if (state.fullscreen) {
        SDL_SetWindowFullscreen(window, true);
    }
}

void drawLoadingFrame(SDL_Renderer* renderer, std::uint64_t elapsedMs, const char* title, const char* subtitle) {
    SDL_SetRenderLogicalPresentation(renderer, kBaseWidth, kBaseHeight, SDL_LOGICAL_PRESENTATION_LETTERBOX);

    fillRect(renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 20, 66, 52);
    fillRect(renderer, SDL_FRect{0, 0, kBaseWidth, 220.0f}, 13, 44, 36);

    const SDL_FRect panel{68.0f, 252.0f, 344.0f, 154.0f};
    fillRect(renderer, panel, 242, 234, 207, 245);
    strokeRect(renderer, panel, 72, 55, 34);

    setColor(renderer, 42, 34, 26);
    const std::string titleText = title;
    const std::string subtitleText = subtitle;
    uiText(renderer, kBaseWidth * 0.5f - uiTextWidth(titleText, 1.5f) * 0.5f, 118.0f, titleText, 1.5f);
    uiText(renderer, panel.x + panel.w * 0.5f - uiTextWidth(subtitleText) * 0.5f, panel.y + 28.0f, subtitleText);

    const float progress = std::clamp(static_cast<float>(elapsedMs) / static_cast<float>(kLoadingDurationMs), 0.0f, 1.0f);
    const SDL_FRect barBg{panel.x + 34.0f, panel.y + 88.0f, panel.w - 68.0f, 18.0f};
    fillRect(renderer, barBg, 44, 83, 66, 180);
    strokeRect(renderer, barBg, 234, 214, 160, 180);
    fillRect(renderer, SDL_FRect{barBg.x + 2.0f, barBg.y + 2.0f, (barBg.w - 4.0f) * progress, barBg.h - 4.0f}, 228, 179, 70);

    const std::array<float, 3> dotsX{panel.x + 132.0f, panel.x + 164.0f, panel.x + 196.0f};
    for (std::size_t i = 0; i < dotsX.size(); ++i) {
        const float phase = static_cast<float>((elapsedMs + i * 90) % 360) / 360.0f;
        const float pulse = 0.5f + 0.5f * static_cast<float>(std::sin(phase * 6.283185307f));
        const float size = 8.0f + pulse * 4.0f;
        fillRect(renderer, SDL_FRect{dotsX[i], panel.y + 118.0f, size, size}, 245, 239, 219);
    }

    SDL_RenderPresent(renderer);
}

}  // namespace

void showLoadingScene(const AppWindowState& windowState, const char* title, const char* subtitle) {
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        return;
    }

    SDL_Window* window = SDL_CreateWindow(title, windowState.width, windowState.height, SDL_WINDOW_RESIZABLE);
    if (!window) {
        SDL_Quit();
        return;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, nullptr);
    if (!renderer) {
        SDL_DestroyWindow(window);
        SDL_Quit();
        return;
    }

    applyWindowState(window, windowState);
    SDL_SetRenderVSync(renderer, 1);
    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);

    const std::uint64_t startTicks = SDL_GetTicks();
    while (SDL_GetTicks() - startTicks < kLoadingDurationMs) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                SDL_DestroyRenderer(renderer);
                SDL_DestroyWindow(window);
                SDL_Quit();
                return;
            }
        }

        drawLoadingFrame(renderer, SDL_GetTicks() - startTicks, title, subtitle);
        SDL_Delay(16);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}