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
constexpr std::uint64_t kLoadingDurationMs = 420;

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

void fillCircle(SDL_Renderer* renderer, float cx, float cy, float radius, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    const int drawRadius = std::max(1, static_cast<int>(std::round(radius)));
    for (int dy = -drawRadius; dy <= drawRadius; ++dy) {
        const float span = std::sqrt(std::max(0.0f, radius * radius - static_cast<float>(dy * dy)));
        SDL_RenderLine(renderer, cx - span, cy + static_cast<float>(dy), cx + span, cy + static_cast<float>(dy));
    }
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

    fillRect(renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 14, 26, 33);
    fillRect(renderer, SDL_FRect{0, 0, kBaseWidth, 318.0f}, 22, 47, 59);
    fillRect(renderer, SDL_FRect{0, 318.0f, kBaseWidth, 536.0f}, 18, 34, 42);
    fillRect(renderer, SDL_FRect{0, 0, kBaseWidth, 6.0f}, 232, 192, 102);

    for (int i = 0; i < 10; ++i) {
        const float x = -20.0f + static_cast<float>(i) * 58.0f;
        fillRect(renderer, SDL_FRect{x, 74.0f, 14.0f, 680.0f}, 255, 255, 255, 8);
    }

    const SDL_FRect heroGlow{74.0f, 148.0f, 332.0f, 332.0f};
    fillRect(renderer, heroGlow, 32, 78, 84, 50);
    fillCircle(renderer, kBaseWidth * 0.5f, 242.0f, 88.0f, 245, 191, 100, 28);
    fillCircle(renderer, kBaseWidth * 0.5f, 242.0f, 54.0f, 250, 224, 164, 38);

    const SDL_FRect shadow{52.0f, 222.0f, 376.0f, 232.0f};
    fillRect(renderer, shadow, 0, 0, 0, 58);
    const SDL_FRect panel{60.0f, 210.0f, 360.0f, 232.0f};
    fillRect(renderer, panel, 233, 228, 209, 246);
    fillRect(renderer, SDL_FRect{panel.x + 10.0f, panel.y + 10.0f, panel.w - 20.0f, panel.h - 20.0f}, 244, 239, 224, 236);
    strokeRect(renderer, panel, 76, 64, 48);

    const SDL_FRect badge{panel.x + 22.0f, panel.y + 18.0f, 88.0f, 28.0f};
    fillRect(renderer, badge, 33, 59, 66, 255);
    strokeRect(renderer, badge, 232, 192, 102, 180);
    setColor(renderer, 248, 241, 219, 255);
    uiText(renderer, badge.x + badge.w * 0.5f - uiTextWidth("Loading", 0.86f) * 0.5f, badge.y + 7.0f, "Loading", 0.86f);

    setColor(renderer, 35, 31, 28, 255);
    const std::string titleText = title;
    const std::string subtitleText = subtitle;
    uiText(renderer, panel.x + 22.0f, panel.y + 64.0f, titleText, 1.62f);
    setColor(renderer, 85, 79, 70, 255);
    uiText(renderer, panel.x + 22.0f, panel.y + 102.0f, subtitleText, 1.0f);
    uiText(renderer, panel.x + 22.0f, panel.y + 128.0f, "Preparing scene and assets", 0.88f);

    const float progress = std::clamp(static_cast<float>(elapsedMs) / static_cast<float>(kLoadingDurationMs), 0.0f, 1.0f);
    const SDL_FRect barBg{panel.x + 22.0f, panel.y + 168.0f, panel.w - 44.0f, 16.0f};
    fillRect(renderer, barBg, 37, 49, 54, 220);
    strokeRect(renderer, barBg, 228, 207, 152, 120);
    const float fillWidth = (barBg.w - 4.0f) * progress;
    fillRect(renderer, SDL_FRect{barBg.x + 2.0f, barBg.y + 2.0f, fillWidth, barBg.h - 4.0f}, 234, 191, 92);
    fillRect(renderer, SDL_FRect{barBg.x + 2.0f, barBg.y + 2.0f, fillWidth, (barBg.h - 4.0f) * 0.45f}, 251, 232, 176, 110);

    const int progressPercent = static_cast<int>(std::round(progress * 100.0f));
    const std::string percentText = std::to_string(progressPercent) + "%";
    setColor(renderer, 54, 50, 43, 255);
    uiText(renderer, panel.x + panel.w - uiTextWidth(percentText, 0.88f) - 22.0f, panel.y + 145.0f, percentText, 0.88f);

    const std::array<float, 4> dotsX{panel.x + 24.0f, panel.x + 52.0f, panel.x + 80.0f, panel.x + 108.0f};
    for (std::size_t i = 0; i < dotsX.size(); ++i) {
        const float phase = static_cast<float>((elapsedMs + i * 80) % 420) / 420.0f;
        const float pulse = 0.5f + 0.5f * static_cast<float>(std::sin(phase * 6.283185307f));
        fillCircle(renderer, dotsX[i], panel.y + 203.0f, 4.0f + pulse * 4.0f, 42, 72, 77, 255);
        fillCircle(renderer, dotsX[i], panel.y + 203.0f, 2.0f + pulse * 1.8f, 244, 232, 191, 240);
    }

    setColor(renderer, 88, 96, 104, 255);
    uiText(renderer, panel.x + 134.0f, panel.y + 195.0f, "Please wait", 0.84f);

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