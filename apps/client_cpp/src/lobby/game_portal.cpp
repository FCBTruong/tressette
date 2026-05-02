#include "game_portal.h"

#include <SDL3/SDL.h>
#include <SDL3_image/SDL_image.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <filesystem>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

constexpr int kBaseWidth = 480;
constexpr int kBaseHeight = 854;

struct PortalEntry {
    std::string title;
    PortalSelection selection = PortalSelection::Quit;
    SDL_FRect rect{};
};

struct PortalApp {
    SDL_Window* window = nullptr;
    SDL_Renderer* renderer = nullptr;
    std::vector<PortalEntry> entries;
    float elapsed = 0.0f;
    int pressedIndex = -1;
    bool running = true;
    PortalSelection result = PortalSelection::Quit;
    AppWindowState windowState{};
};

std::unordered_map<std::string, SDL_Texture*> g_textureCache;

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

AppWindowState snapshotWindowState(SDL_Window* window) {
    AppWindowState state;
    SDL_GetWindowSize(window, &state.width, &state.height);
    SDL_GetWindowPosition(window, &state.posX, &state.posY);
    state.hasPosition = true;
    const SDL_WindowFlags flags = SDL_GetWindowFlags(window);
    state.maximized = (flags & SDL_WINDOW_MAXIMIZED) != 0;
    state.fullscreen = (flags & SDL_WINDOW_FULLSCREEN) != 0;
    return state;
}

bool pointInRect(float x, float y, const SDL_FRect& rect) {
    return x >= rect.x && x <= rect.x + rect.w && y >= rect.y && y <= rect.y + rect.h;
}

void setColor(SDL_Renderer* renderer, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    SDL_SetRenderDrawColor(renderer, r, g, b, a);
}

float debugTextWidth(const std::string& value) {
    return static_cast<float>(value.size()) * 8.0f;
}

float uiTextWidth(const std::string& value, float scale = 1.35f) {
    return debugTextWidth(value) * scale;
}

void fillRect(SDL_Renderer* renderer, const SDL_FRect& rect, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    SDL_RenderFillRect(renderer, &rect);
}

void strokeRect(SDL_Renderer* renderer, const SDL_FRect& rect, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    SDL_RenderRect(renderer, &rect);
}

float uiTextWidth(const std::string& value, float scale);
void uiText(SDL_Renderer* renderer, float x, float y, const std::string& value, float scale);

SDL_FRect insetRect(SDL_FRect rect, float amount) {
    rect.x += amount;
    rect.y += amount;
    rect.w -= amount * 2.0f;
    rect.h -= amount * 2.0f;
    return rect;
}

void fillCircle(SDL_Renderer* renderer, float cx, float cy, float radius, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    const int drawRadius = std::max(1, static_cast<int>(radius));
    for (int dy = -drawRadius; dy <= drawRadius; ++dy) {
        const float span = std::sqrt(std::max(0.0f, radius * radius - static_cast<float>(dy * dy)));
        SDL_RenderLine(renderer, cx - span, cy + static_cast<float>(dy), cx + span, cy + static_cast<float>(dy));
    }
}

std::filesystem::path findGameIconRoot() {
#ifdef __ANDROID__
    return std::filesystem::path{"game_icons"};
#else
    const std::array<std::filesystem::path, 4> candidates{
        std::filesystem::path{"assets/game_icons"},
        std::filesystem::path{"../client_cpp/assets/game_icons"},
        std::filesystem::path{"../../client_cpp/assets/game_icons"},
        std::filesystem::current_path() / "assets/game_icons",
    };

    for (const auto& candidate : candidates) {
        std::error_code ec;
        const auto full = std::filesystem::weakly_canonical(candidate, ec);
        const auto checkPath = ec ? candidate : full;
        if (std::filesystem::exists(checkPath / "tressette_icon.png") &&
            std::filesystem::exists(checkPath / "memory_icon.png")) {
            return checkPath;
        }
    }
    return {};
#endif
}

std::filesystem::path iconTexturePath(PortalSelection selection) {
    static const std::filesystem::path iconRoot = findGameIconRoot();
    if (selection == PortalSelection::Farm) {
        return iconRoot / "farm_icon.png";
    }
    if (selection == PortalSelection::FlappyBird) {
        return iconRoot / "flappy_icon.png";
    }
    if (selection == PortalSelection::Scopa) {
        return iconRoot / "scopa_icon.png";
    }
    if (selection == PortalSelection::MemoryCards) {
        return iconRoot / "memory_icon.png";
    }
    if (selection == PortalSelection::Tressette) {
        return iconRoot / "tressette_icon.png";
    }
    return {};
}

SDL_Texture* loadTexture(SDL_Renderer* renderer, const std::filesystem::path& path) {
    if (path.empty()) return nullptr;
    const std::string key = path.string();
    if (auto it = g_textureCache.find(key); it != g_textureCache.end()) {
        return it->second;
    }

    SDL_Texture* texture = IMG_LoadTexture(renderer, key.c_str());
    if (!texture) {
        SDL_Log("IMG_LoadTexture failed for %s: %s", key.c_str(), SDL_GetError());
        return nullptr;
    }
    SDL_SetTextureScaleMode(texture, SDL_SCALEMODE_LINEAR);
    g_textureCache[key] = texture;
    return texture;
}

void destroyTextures() {
    for (auto& [_, texture] : g_textureCache) {
        if (texture) {
            SDL_DestroyTexture(texture);
        }
    }
    g_textureCache.clear();
}

void drawTextureContain(SDL_Renderer* renderer, SDL_Texture* texture, const SDL_FRect& bounds) {
    if (!texture) return;
    float textureW = 0.0f;
    float textureH = 0.0f;
    if (!SDL_GetTextureSize(texture, &textureW, &textureH) || textureW <= 0.0f || textureH <= 0.0f) {
        return;
    }
    const float scale = std::min(bounds.w / textureW, bounds.h / textureH);
    const SDL_FRect dst{
        bounds.x + (bounds.w - textureW * scale) * 0.5f,
        bounds.y + (bounds.h - textureH * scale) * 0.5f,
        textureW * scale,
        textureH * scale,
    };
    SDL_RenderTexture(renderer, texture, nullptr, &dst);
}

void drawFallbackPortalIcon(SDL_Renderer* renderer, const SDL_FRect& rect, PortalSelection selection, const std::string& title) {
    if (selection == PortalSelection::FlappyBird) {
        const SDL_FRect pipeTop{rect.x + rect.w * 0.16f, rect.y + 28.0f, 40.0f, 54.0f};
        const SDL_FRect pipeBottom{rect.x + rect.w * 0.68f, rect.y + 80.0f, 40.0f, 54.0f};
        fillRect(renderer, pipeTop, 79, 194, 111, 245);
        fillRect(renderer, pipeBottom, 79, 194, 111, 245);
        fillRect(renderer, SDL_FRect{pipeTop.x - 4.0f, pipeTop.y + pipeTop.h - 12.0f, pipeTop.w + 8.0f, 12.0f}, 51, 132, 79, 255);
        fillRect(renderer, SDL_FRect{pipeBottom.x - 4.0f, pipeBottom.y, pipeBottom.w + 8.0f, 12.0f}, 51, 132, 79, 255);
        strokeRect(renderer, pipeTop, 25, 92, 48, 255);
        strokeRect(renderer, pipeBottom, 25, 92, 48, 255);
        fillCircle(renderer, rect.x + rect.w * 0.48f, rect.y + rect.h * 0.5f, 19.0f, 255, 220, 87, 250);
        fillCircle(renderer, rect.x + rect.w * 0.45f, rect.y + rect.h * 0.45f, 7.0f, 255, 245, 214, 240);
        fillRect(renderer, SDL_FRect{rect.x + rect.w * 0.51f, rect.y + rect.h * 0.48f, 14.0f, 7.0f}, 238, 116, 52, 255);
    } else if (selection == PortalSelection::Scopa) {
        const SDL_FRect leftCard{rect.x + rect.w * 0.24f, rect.y + 30.0f, 56.0f, 82.0f};
        const SDL_FRect rightCard{rect.x + rect.w * 0.46f, rect.y + 42.0f, 56.0f, 82.0f};
        fillRect(renderer, leftCard, 247, 240, 223, 250);
        fillRect(renderer, rightCard, 247, 240, 223, 250);
        strokeRect(renderer, leftCard, 76, 54, 39, 255);
        strokeRect(renderer, rightCard, 76, 54, 39, 255);
        fillCircle(renderer, rect.x + rect.w * 0.62f, rect.y + rect.h * 0.42f, 15.0f, 239, 191, 72, 250);
        fillCircle(renderer, rect.x + rect.w * 0.62f, rect.y + rect.h * 0.42f, 8.0f, 252, 228, 164, 220);
        setColor(renderer, 184, 46, 38, 255);
        uiText(renderer, leftCard.x + 12.0f, leftCard.y + 16.0f, "7", 1.05f);
        uiText(renderer, rightCard.x + 14.0f, rightCard.y + 18.0f, "A", 1.05f);
    } else if (selection == PortalSelection::Farm) {
        const SDL_FRect soil{rect.x + 26.0f, rect.y + 42.0f, rect.w - 52.0f, 74.0f};
        fillRect(renderer, soil, 132, 92, 58, 245);
        strokeRect(renderer, soil, 78, 55, 35, 255);
        for (int i = 0; i < 3; ++i) {
            const float cx = soil.x + 34.0f + static_cast<float>(i) * 36.0f;
            fillCircle(renderer, cx, soil.y + 48.0f, 8.0f, 87, 186, 90, 255);
            fillCircle(renderer, cx - 5.0f, soil.y + 42.0f, 5.0f, 112, 214, 102, 255);
            fillCircle(renderer, cx + 5.0f, soil.y + 42.0f, 5.0f, 112, 214, 102, 255);
        }
        fillCircle(renderer, rect.x + rect.w - 34.0f, rect.y + 42.0f, 12.0f, 245, 208, 102, 240);
    }
    setColor(renderer, 251, 240, 213, 255);
    uiText(renderer, rect.x + rect.w * 0.5f - uiTextWidth(title, 1.18f) * 0.5f, rect.y + rect.h - 36.0f, title, 1.18f);
}

void uiText(SDL_Renderer* renderer, float x, float y, const std::string& value, float scale = 1.35f) {
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

float easeOutBack(float t) {
    t = std::clamp(t, 0.0f, 1.0f);
    constexpr float c1 = 1.70158f;
    constexpr float c3 = c1 + 1.0f;
    const float inv = t - 1.0f;
    return 1.0f + c3 * inv * inv * inv + c1 * inv * inv;
}

SDL_FPoint windowToLogical(SDL_Renderer* renderer, float x, float y) {
    int outW = 0;
    int outH = 0;
    SDL_GetRenderOutputSize(renderer, &outW, &outH);
    const float scale = std::min(outW / static_cast<float>(kBaseWidth), outH / static_cast<float>(kBaseHeight));
    const float viewW = kBaseWidth * scale;
    const float viewH = kBaseHeight * scale;
    const float offsetX = (outW - viewW) * 0.5f;
    const float offsetY = (outH - viewH) * 0.5f;
    return SDL_FPoint{(x - offsetX) / scale, (y - offsetY) / scale};
}

void layoutEntries(PortalApp& app) {
    if (app.entries.size() >= 4) {
        const float itemW = 158.0f;
        const float itemH = 172.0f;
        const float gapX = 18.0f;
        const float gapY = 18.0f;
        const float startX = (kBaseWidth - (itemW * 2.0f + gapX)) * 0.5f;
        const float startY = 244.0f;
        for (std::size_t i = 0; i < app.entries.size(); ++i) {
            const int row = static_cast<int>(i) / 2;
            const int col = static_cast<int>(i) % 2;
            float x = startX + static_cast<float>(col) * (itemW + gapX);
            if (i == app.entries.size() - 1 && (app.entries.size() % 2) == 1) {
                x = (kBaseWidth - itemW) * 0.5f;
            }
            app.entries[i].rect = SDL_FRect{
                x,
                startY + static_cast<float>(row) * (itemH + gapY),
                itemW,
                itemH,
            };
        }
        return;
    }

    const float itemW = 336.0f;
    const float itemH = 164.0f;
    const float startY = 216.0f;
    const float gap = 22.0f;
    for (std::size_t i = 0; i < app.entries.size(); ++i) {
        app.entries[i].rect = SDL_FRect{
            (kBaseWidth - itemW) * 0.5f,
            startY + static_cast<float>(i) * (itemH + gap),
            itemW,
            itemH,
        };
    }
}

void drawPortal(PortalApp& app) {
    SDL_SetRenderLogicalPresentation(app.renderer, kBaseWidth, kBaseHeight, SDL_LOGICAL_PRESENTATION_LETTERBOX);
    fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 10, 20, 31);
    for (int i = 0; i < 26; ++i) {
        const float y = static_cast<float>(i) * 34.0f;
        const std::uint8_t tone = static_cast<std::uint8_t>(24 + i * 3);
        fillRect(app.renderer, SDL_FRect{0.0f, y, static_cast<float>(kBaseWidth), 40.0f}, tone, static_cast<std::uint8_t>(36 + i * 2), static_cast<std::uint8_t>(50 + i * 3), 88);
    }

    fillCircle(app.renderer, 84.0f, 126.0f, 128.0f, 62, 150, 138, 84);
    fillCircle(app.renderer, 414.0f, 218.0f, 108.0f, 250, 176, 87, 54);
    fillCircle(app.renderer, 392.0f, 734.0f, 148.0f, 44, 96, 168, 56);
    fillCircle(app.renderer, 126.0f, 690.0f, 102.0f, 90, 190, 184, 38);

    for (int i = -18; i < 32; ++i) {
        setColor(app.renderer, 255, 255, 255, 14);
        SDL_RenderLine(app.renderer, static_cast<float>(i) * 24.0f, 0.0f, static_cast<float>(i) * 24.0f + 180.0f, static_cast<float>(kBaseHeight));
    }

    for (int row = 0; row < 20; ++row) {
        for (int col = 0; col < 12; ++col) {
            const float px = 28.0f + static_cast<float>(col) * 38.0f + ((row % 2 == 0) ? 0.0f : 18.0f);
            const float py = 104.0f + static_cast<float>(row) * 34.0f;
            fillCircle(app.renderer, px, py, 1.5f, 255, 255, 255, 22);
        }
    }

    fillRect(app.renderer, SDL_FRect{18.0f, 28.0f, kBaseWidth - 36.0f, 158.0f}, 9, 17, 28, 150);
    fillRect(app.renderer, SDL_FRect{24.0f, 34.0f, kBaseWidth - 48.0f, 146.0f}, 255, 255, 255, 20);
    strokeRect(app.renderer, SDL_FRect{24.0f, 34.0f, kBaseWidth - 48.0f, 146.0f}, 235, 214, 170, 110);

    const std::string title = "Game Portal";
    const std::string subtitle = "Choose a table and jump in.";
    const float titleY = 76.0f;
    setColor(app.renderer, 248, 238, 212);
    uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(title, 1.62f) * 0.5f, titleY, title, 1.62f);
    setColor(app.renderer, 191, 216, 212);
    uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(subtitle, 1.04f) * 0.5f, 122.0f, subtitle, 1.04f);

    for (std::size_t i = 0; i < app.entries.size(); ++i) {
        SDL_FRect rect = app.entries[i].rect;
        const float introT = std::clamp((app.elapsed - static_cast<float>(i) * 0.06f) / 0.34f, 0.0f, 1.0f);
        const float introScale = 0.92f + 0.08f * easeOutBack(introT);
        rect = SDL_FRect{
            rect.x + (rect.w - rect.w * introScale) * 0.5f,
            rect.y + (rect.h - rect.h * introScale) * 0.5f,
            rect.w * introScale,
            rect.h * introScale,
        };

        if (static_cast<int>(i) == app.pressedIndex) {
            constexpr float pressedScale = 0.97f;
            rect = SDL_FRect{
                rect.x + (rect.w - rect.w * pressedScale) * 0.5f,
                rect.y + (rect.h - rect.h * pressedScale) * 0.5f,
                rect.w * pressedScale,
                rect.h * pressedScale,
            };
        }

        fillRect(app.renderer, SDL_FRect{rect.x + 6.0f, rect.y + 10.0f, rect.w, rect.h}, 5, 8, 13, 84);
        fillRect(app.renderer, rect, 16, 28, 42, 232);
        fillRect(app.renderer, insetRect(rect, 3.0f), 255, 255, 255, 16);
        fillRect(app.renderer, SDL_FRect{rect.x, rect.y, rect.w, rect.h * 0.54f}, 255, 255, 255, 10);
        strokeRect(app.renderer, rect, 234, 218, 180, 210);
        strokeRect(app.renderer, insetRect(rect, 5.0f), 79, 132, 154, 100);

        const float pulse = 0.5f + 0.5f * std::sin(app.elapsed * 1.7f + static_cast<float>(i) * 1.1f);
        const SDL_FRect glowRect{rect.x - 18.0f, rect.y - 16.0f, rect.w + 36.0f, rect.h + 32.0f};
        if (app.entries[i].selection == PortalSelection::Tressette) {
            fillCircle(app.renderer, glowRect.x + glowRect.w * 0.28f, glowRect.y + glowRect.h * 0.34f, 46.0f + pulse * 10.0f, 252, 181, 72, 22);
        } else if (app.entries[i].selection == PortalSelection::Farm) {
            fillCircle(app.renderer, glowRect.x + glowRect.w * 0.5f, glowRect.y + glowRect.h * 0.4f, 48.0f + pulse * 10.0f, 110, 212, 112, 24);
        } else if (app.entries[i].selection == PortalSelection::FlappyBird) {
            fillCircle(app.renderer, glowRect.x + glowRect.w * 0.5f, glowRect.y + glowRect.h * 0.4f, 48.0f + pulse * 10.0f, 118, 229, 127, 24);
        } else if (app.entries[i].selection == PortalSelection::Scopa) {
            fillCircle(app.renderer, glowRect.x + glowRect.w * 0.5f, glowRect.y + glowRect.h * 0.4f, 48.0f + pulse * 10.0f, 243, 202, 102, 24);
        } else {
            fillCircle(app.renderer, glowRect.x + glowRect.w * 0.72f, glowRect.y + glowRect.h * 0.34f, 44.0f + pulse * 10.0f, 90, 164, 255, 22);
        }

        SDL_Texture* icon = loadTexture(app.renderer, iconTexturePath(app.entries[i].selection));
        if (icon) {
            drawTextureContain(app.renderer, icon, SDL_FRect{rect.x + 24.0f, rect.y + 14.0f, rect.w - 48.0f, rect.h - 28.0f});
        } else {
            drawFallbackPortalIcon(app.renderer, rect, app.entries[i].selection, app.entries[i].title);
        }
    }

    SDL_RenderPresent(app.renderer);
}

bool init(PortalApp& app, const AppWindowState& initialWindowState) {
    SDL_SetAppMetadata("Game Portal", "0.1.0", "com.gamestudio.portal");
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return false;
    }
    app.window = SDL_CreateWindow("Game Portal", kBaseWidth, kBaseHeight, SDL_WINDOW_RESIZABLE);
    if (!app.window) {
        SDL_Log("SDL_CreateWindow failed: %s", SDL_GetError());
        return false;
    }
    app.renderer = SDL_CreateRenderer(app.window, nullptr);
    if (!app.renderer) {
        SDL_Log("SDL_CreateRenderer failed: %s", SDL_GetError());
        return false;
    }
    applyWindowState(app.window, initialWindowState);
    SDL_SetRenderVSync(app.renderer, 1);
    SDL_SetRenderDrawBlendMode(app.renderer, SDL_BLENDMODE_BLEND);
    app.entries = {
        {"Tressette", PortalSelection::Tressette, {}},
        {"Flappy Bird", PortalSelection::FlappyBird, {}},
        {"Memory Cards", PortalSelection::MemoryCards, {}},
        {"Scopa", PortalSelection::Scopa, {}},
        {"Tiny Farm", PortalSelection::Farm, {}},
    };
    layoutEntries(app);
    return true;
}

void shutdown(PortalApp& app) {
    destroyTextures();
    if (app.renderer) SDL_DestroyRenderer(app.renderer);
    if (app.window) SDL_DestroyWindow(app.window);
    SDL_Quit();
}

void handlePointerDown(PortalApp& app, float x, float y) {
    app.pressedIndex = -1;
    for (std::size_t i = 0; i < app.entries.size(); ++i) {
        if (pointInRect(x, y, app.entries[i].rect)) {
            app.pressedIndex = static_cast<int>(i);
            return;
        }
    }
}

void handlePointerUp(PortalApp& app, float x, float y) {
    const int pressedIndex = app.pressedIndex;
    app.pressedIndex = -1;
    if (pressedIndex < 0) {
        return;
    }
    const std::size_t index = static_cast<std::size_t>(pressedIndex);
    if (index < app.entries.size() && pointInRect(x, y, app.entries[index].rect)) {
        app.result = app.entries[index].selection;
        app.running = false;
    }
}

}  // namespace

PortalResult runGamePortal(const AppWindowState& initialWindowState) {
    PortalApp app;
    if (!init(app, initialWindowState)) {
        shutdown(app);
        return PortalResult{PortalSelection::Quit, initialWindowState};
    }

    std::uint64_t lastTicks = SDL_GetTicks();
    while (app.running) {
        const std::uint64_t nowTicks = SDL_GetTicks();
        const float delta = static_cast<float>(nowTicks - lastTicks) / 1000.0f;
        lastTicks = nowTicks;
        app.elapsed += delta;

        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                app.result = PortalSelection::Quit;
                app.running = false;
            } else if (event.type == SDL_EVENT_KEY_DOWN) {
                if (event.key.key == SDLK_ESCAPE) {
                    app.result = PortalSelection::Quit;
                    app.running = false;
                }
            } else if (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN) {
                if (event.button.which == SDL_TOUCH_MOUSEID) {
                    continue;
                }
                const SDL_FPoint logical = windowToLogical(app.renderer, event.button.x, event.button.y);
                handlePointerDown(app, logical.x, logical.y);
            } else if (event.type == SDL_EVENT_MOUSE_BUTTON_UP) {
                if (event.button.which == SDL_TOUCH_MOUSEID) {
                    continue;
                }
                const SDL_FPoint logical = windowToLogical(app.renderer, event.button.x, event.button.y);
                handlePointerUp(app, logical.x, logical.y);
            } else if (event.type == SDL_EVENT_FINGER_DOWN) {
                int outW = 0;
                int outH = 0;
                SDL_GetRenderOutputSize(app.renderer, &outW, &outH);
                const SDL_FPoint logical = windowToLogical(app.renderer,
                                                           event.tfinger.x * static_cast<float>(outW),
                                                           event.tfinger.y * static_cast<float>(outH));
                handlePointerDown(app, logical.x, logical.y);
            } else if (event.type == SDL_EVENT_FINGER_UP) {
                int outW = 0;
                int outH = 0;
                SDL_GetRenderOutputSize(app.renderer, &outW, &outH);
                const SDL_FPoint logical = windowToLogical(app.renderer,
                                                           event.tfinger.x * static_cast<float>(outW),
                                                           event.tfinger.y * static_cast<float>(outH));
                handlePointerUp(app, logical.x, logical.y);
            }
        }

        drawPortal(app);
        SDL_Delay(16);
    }

    app.windowState = snapshotWindowState(app.window);
    const PortalResult result{app.result, app.windowState};
    shutdown(app);
    return result;
}