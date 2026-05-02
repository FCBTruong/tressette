#include "memory_cards_game.h"

#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <random>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

constexpr int kBaseWidth = 480;
constexpr int kBaseHeight = 854;

struct LevelConfig {
    int size = 2;
    int cell = 72;
};

constexpr std::array<LevelConfig, 5> kLevels{{
    {2, 72},
    {4, 62},
    {6, 50},
    {8, 38},
    {10, 32},
}};

constexpr int kArtKindCount = 10;
constexpr std::array<SDL_Color, 5> kArtPalettes{{
    SDL_Color{238, 111, 87, 255},
    SDL_Color{250, 184, 76, 255},
    SDL_Color{74, 182, 153, 255},
    SDL_Color{74, 127, 210, 255},
    SDL_Color{164, 115, 212, 255},
}};

constexpr std::array<std::uint32_t, 50> kEmojiCodepoints{{
    0x1F436, 0x1F431, 0x1F438, 0x1F43C, 0x1F98A, 0x1F435, 0x1F42F, 0x1F981, 0x1F98B, 0x1F984,
    0x1F437, 0x1F42E, 0x1F439, 0x1F430, 0x1F43B, 0x1F428, 0x1F42D, 0x1F414, 0x1F423, 0x1F986,
    0x1F34E, 0x1F34B, 0x1F347, 0x1F353, 0x1F352, 0x1F349, 0x1F34D, 0x1F955, 0x1F33D, 0x1F966,
    0x1F697, 0x1F695, 0x1F699, 0x1F6B2, 0x2708, 0x1F680, 0x26F5, 0x1F6F8, 0x1F6A4, 0x1F3AE,
    0x1F3B8, 0x1F3B5, 0x1F381, 0x1F388, 0x1F48E, 0x2B50, 0x1F525, 0x1F4A7, 0x1F33B, 0x1F335,
}};

constexpr float kFlipSpeed = 7.8f;
constexpr float kMinFlipScale = 0.08f;

enum class SoundEffect : int { UiTap, WinCongrat };

struct LoadedSound {
    SDL_AudioSpec spec{};
    Uint8* data = nullptr;
    Uint32 length = 0;
};

struct MemoryCard {
    int id = -1;
    int artId = 0;
    bool flipped = false;
    bool matched = false;
    float flip = 0.0f;
    SDL_FRect rect{};
};

struct EmojiTexture {
    SDL_Texture* texture = nullptr;
    int width = 0;
    int height = 0;
};

struct FireworkParticle {
    SDL_FPoint position{};
    SDL_FPoint velocity{};
    float elapsed = 0.0f;
    float duration = 1.0f;
    std::uint8_t r = 255;
    std::uint8_t g = 220;
    std::uint8_t b = 140;
};

struct App {
    SDL_Window* window = nullptr;
    SDL_Renderer* renderer = nullptr;
    TTF_Font* emojiFont = nullptr;
    SDL_AudioDeviceID audioDevice = 0;
    std::mt19937 rng{std::random_device{}()};
    std::vector<MemoryCard> cards;
    std::vector<int> selectedIds;
    std::vector<FireworkParticle> fireworks;
    std::vector<SDL_AudioStream*> activeAudioStreams;
    std::unordered_map<int, EmojiTexture> emojiCache;
    SDL_FRect backRect{};
    SDL_FRect restartRect{};
    SDL_FRect modalNextRect{};
    SDL_FRect modalRestartRect{};
    float elapsed = 0.0f;
    float timer = 0.0f;
    float mismatchDelay = -1.0f;
    float fireworkSpawnTimer = 0.0f;
    int levelIndex = 0;
    int moves = 0;
    int pendingMismatchA = -1;
    int pendingMismatchB = -1;
    bool running = true;
    bool started = false;
    bool won = false;
    bool locked = false;
    bool audioEnabled = true;
    bool winSoundPlayed = false;
    MemoryCardsExitAction exitAction = MemoryCardsExitAction::Quit;
    AppWindowState windowState{};
};

std::filesystem::path g_soundAssetRoot;
std::unordered_map<int, LoadedSound> g_soundCache;

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

SDL_Color mixColor(SDL_Color a, SDL_Color b, float t) {
    t = std::clamp(t, 0.0f, 1.0f);
    return SDL_Color{
        static_cast<std::uint8_t>(std::lerp(static_cast<float>(a.r), static_cast<float>(b.r), t)),
        static_cast<std::uint8_t>(std::lerp(static_cast<float>(a.g), static_cast<float>(b.g), t)),
        static_cast<std::uint8_t>(std::lerp(static_cast<float>(a.b), static_cast<float>(b.b), t)),
        static_cast<std::uint8_t>(std::lerp(static_cast<float>(a.a), static_cast<float>(b.a), t)),
    };
}

SDL_FRect insetRect(SDL_FRect rect, float amount) {
    rect.x += amount;
    rect.y += amount;
    rect.w -= amount * 2.0f;
    rect.h -= amount * 2.0f;
    return rect;
}

void fillCircle(SDL_Renderer* renderer, float cx, float cy, float radius, SDL_Color color) {
    setColor(renderer, color.r, color.g, color.b, color.a);
    const int r = std::max(1, static_cast<int>(std::round(radius)));
    for (int dy = -r; dy <= r; ++dy) {
        const float fx = std::sqrt(std::max(0.0f, radius * radius - static_cast<float>(dy * dy)));
        SDL_RenderLine(renderer, cx - fx, cy + static_cast<float>(dy), cx + fx, cy + static_cast<float>(dy));
    }
}

void fillDiamond(SDL_Renderer* renderer, float cx, float cy, float radiusX, float radiusY, SDL_Color color) {
    setColor(renderer, color.r, color.g, color.b, color.a);
    const int h = std::max(1, static_cast<int>(std::round(radiusY)));
    for (int dy = -h; dy <= h; ++dy) {
        const float t = 1.0f - (std::fabs(static_cast<float>(dy)) / radiusY);
        const float span = std::max(1.0f, radiusX * t);
        SDL_RenderLine(renderer, cx - span, cy + static_cast<float>(dy), cx + span, cy + static_cast<float>(dy));
    }
}

void fillTriangle(SDL_Renderer* renderer, SDL_FPoint a, SDL_FPoint b, SDL_FPoint c, SDL_Color color) {
    std::array<SDL_FPoint, 3> points{{a, b, c}};
    std::sort(points.begin(), points.end(), [](const SDL_FPoint& lhs, const SDL_FPoint& rhs) {
        return lhs.y < rhs.y;
    });
    const SDL_FPoint p0 = points[0];
    const SDL_FPoint p1 = points[1];
    const SDL_FPoint p2 = points[2];
    setColor(renderer, color.r, color.g, color.b, color.a);
    const int minY = static_cast<int>(std::floor(p0.y));
    const int maxY = static_cast<int>(std::ceil(p2.y));
    for (int y = minY; y <= maxY; ++y) {
        const float fy = static_cast<float>(y);
        std::vector<float> intersections;
        auto addIntersection = [&](SDL_FPoint start, SDL_FPoint end) {
            const float minEdgeY = std::min(start.y, end.y);
            const float maxEdgeY = std::max(start.y, end.y);
            if (std::fabs(end.y - start.y) < 0.001f || fy < minEdgeY || fy > maxEdgeY) {
                return;
            }
            const float t = (fy - start.y) / (end.y - start.y);
            intersections.push_back(start.x + (end.x - start.x) * t);
        };
        addIntersection(p0, p1);
        addIntersection(p1, p2);
        addIntersection(p0, p2);
        if (intersections.size() < 2) {
            continue;
        }
        std::sort(intersections.begin(), intersections.end());
        SDL_RenderLine(renderer, intersections.front(), fy, intersections.back(), fy);
    }
}

void drawCardBack(SDL_Renderer* renderer, const SDL_FRect& rect) {
    fillRect(renderer, rect, 30, 96, 103);
    strokeRect(renderer, rect, 231, 220, 191);
    const SDL_FRect inner = insetRect(rect, 4.0f);
    fillRect(renderer, inner, 23, 77, 86);
    for (float stripe = -rect.h; stripe < rect.w; stripe += 10.0f) {
        setColor(renderer, 255, 255, 255, 24);
        SDL_RenderLine(renderer,
                       rect.x + stripe,
                       rect.y + rect.h,
                       rect.x + stripe + rect.h,
                       rect.y);
    }
}

std::string utf8FromCodepoint(std::uint32_t codepoint) {
    std::string output;
    if (codepoint <= 0x7F) {
        output.push_back(static_cast<char>(codepoint));
    } else if (codepoint <= 0x7FF) {
        output.push_back(static_cast<char>(0xC0 | ((codepoint >> 6) & 0x1F)));
        output.push_back(static_cast<char>(0x80 | (codepoint & 0x3F)));
    } else if (codepoint <= 0xFFFF) {
        output.push_back(static_cast<char>(0xE0 | ((codepoint >> 12) & 0x0F)));
        output.push_back(static_cast<char>(0x80 | ((codepoint >> 6) & 0x3F)));
        output.push_back(static_cast<char>(0x80 | (codepoint & 0x3F)));
    } else {
        output.push_back(static_cast<char>(0xF0 | ((codepoint >> 18) & 0x07)));
        output.push_back(static_cast<char>(0x80 | ((codepoint >> 12) & 0x3F)));
        output.push_back(static_cast<char>(0x80 | ((codepoint >> 6) & 0x3F)));
        output.push_back(static_cast<char>(0x80 | (codepoint & 0x3F)));
    }
    return output;
}

void clearEmojiCache(App& app) {
    for (auto& [_, sprite] : app.emojiCache) {
        if (sprite.texture) {
            SDL_DestroyTexture(sprite.texture);
        }
    }
    app.emojiCache.clear();
}

void releaseLoadedSounds() {
    for (auto& [_, sound] : g_soundCache) {
        if (sound.data) {
            SDL_free(sound.data);
            sound.data = nullptr;
            sound.length = 0;
        }
    }
    g_soundCache.clear();
}

std::filesystem::path findSoundAssetRoot() {
    const std::array<std::filesystem::path, 5> candidates{{
        std::filesystem::path{"assets/sounds"},
        std::filesystem::path{"../assets/sounds"},
        std::filesystem::path{"../../assets/sounds"},
        std::filesystem::current_path() / "assets/sounds",
        std::filesystem::current_path() / "../assets/sounds",
    }};
    for (const auto& candidate : candidates) {
        if (std::filesystem::exists(candidate / "touch_sound.wav")) {
            return candidate;
        }
    }
    return {};
}

std::filesystem::path soundPath(SoundEffect effect) {
    switch (effect) {
    case SoundEffect::UiTap:
        return g_soundAssetRoot / "touch_sound.wav";
    case SoundEffect::WinCongrat:
        return g_soundAssetRoot / "win_congrat_sound.wav";
    }
    return {};
}

LoadedSound* loadSound(App& app, SoundEffect effect) {
    if (!app.audioDevice) {
        return nullptr;
    }
    const int key = static_cast<int>(effect);
    if (auto it = g_soundCache.find(key); it != g_soundCache.end()) {
        return &it->second;
    }

    const auto path = soundPath(effect);
    if (path.empty()) {
        return nullptr;
    }

    LoadedSound sound;
    if (!SDL_LoadWAV(path.string().c_str(), &sound.spec, &sound.data, &sound.length)) {
        SDL_Log("SDL_LoadWAV failed for %s: %s", path.string().c_str(), SDL_GetError());
        return nullptr;
    }
    auto [it, inserted] = g_soundCache.emplace(key, sound);
    return inserted ? &it->second : nullptr;
}

void playSound(App& app, SoundEffect effect) {
    if (!app.audioEnabled || !app.audioDevice) {
        return;
    }
    LoadedSound* sound = loadSound(app, effect);
    if (!sound || !sound->data || sound->length == 0) {
        return;
    }

    SDL_AudioStream* stream = SDL_CreateAudioStream(&sound->spec, nullptr);
    if (!stream) {
        SDL_Log("SDL_CreateAudioStream failed: %s", SDL_GetError());
        return;
    }
    if (!SDL_BindAudioStream(app.audioDevice, stream)) {
        SDL_Log("SDL_BindAudioStream failed: %s", SDL_GetError());
        SDL_DestroyAudioStream(stream);
        return;
    }
    if (!SDL_PutAudioStreamData(stream, sound->data, static_cast<int>(sound->length))) {
        SDL_Log("SDL_PutAudioStreamData failed: %s", SDL_GetError());
        SDL_DestroyAudioStream(stream);
        return;
    }
    if (!SDL_FlushAudioStream(stream)) {
        SDL_Log("SDL_FlushAudioStream failed: %s", SDL_GetError());
        SDL_DestroyAudioStream(stream);
        return;
    }
    app.activeAudioStreams.push_back(stream);
}

void cleanupFinishedAudioStreams(App& app) {
    for (std::size_t i = 0; i < app.activeAudioStreams.size();) {
        SDL_AudioStream* stream = app.activeAudioStreams[i];
        if (SDL_GetAudioStreamQueued(stream) > 0) {
            ++i;
            continue;
        }
        SDL_DestroyAudioStream(stream);
        app.activeAudioStreams.erase(app.activeAudioStreams.begin() + static_cast<std::ptrdiff_t>(i));
    }
}

TTF_Font* loadEmojiFont() {
    constexpr std::array<const char*, 3> paths{{
        "C:/Windows/Fonts/seguiemj.ttf",
        "C:/Windows/Fonts/Segoeuiemoji.ttf",
        "C:/Windows/Fonts/seguisym.ttf",
    }};
    for (const char* path : paths) {
        if (TTF_Font* font = TTF_OpenFont(path, 96.0f)) {
            return font;
        }
    }
    return nullptr;
}

EmojiTexture* getEmojiTexture(App& app, int artId) {
    if (!app.emojiFont || artId < 0 || artId >= static_cast<int>(kEmojiCodepoints.size())) {
        return nullptr;
    }
    auto it = app.emojiCache.find(artId);
    if (it != app.emojiCache.end()) {
        return &it->second;
    }

    const std::string emoji = utf8FromCodepoint(kEmojiCodepoints[static_cast<std::size_t>(artId)]);
    SDL_Surface* surface = TTF_RenderText_Blended(app.emojiFont, emoji.c_str(), 0, SDL_Color{255, 255, 255, 255});
    if (!surface) {
        return nullptr;
    }

    SDL_Texture* texture = SDL_CreateTextureFromSurface(app.renderer, surface);
    if (!texture) {
        SDL_DestroySurface(surface);
        return nullptr;
    }
    SDL_SetTextureScaleMode(texture, SDL_SCALEMODE_LINEAR);
    EmojiTexture sprite;
    sprite.texture = texture;
    sprite.width = surface->w;
    sprite.height = surface->h;
    SDL_DestroySurface(surface);
    auto [inserted, _] = app.emojiCache.emplace(artId, sprite);
    return &inserted->second;
}

void drawCardIcon(SDL_Renderer* renderer, const SDL_FRect& rect, int artId, SDL_Color background) {
    const int paletteIndex = (artId / kArtKindCount) % static_cast<int>(kArtPalettes.size());
    const int kind = artId % kArtKindCount;
    const SDL_Color primary = kArtPalettes[static_cast<std::size_t>(paletteIndex)];
    const SDL_Color secondary = mixColor(primary, SDL_Color{255, 255, 255, 255}, 0.45f);
    const float cx = rect.x + rect.w * 0.5f;
    const float cy = rect.y + rect.h * 0.5f;
    const float unit = std::min(rect.w, rect.h);
    const float core = unit * 0.18f;
    const float outer = unit * 0.29f;
    const float thin = std::max(2.0f, unit * 0.06f);

    switch (kind) {
    case 0:
        fillCircle(renderer, cx, cy, core, primary);
        for (int i = 0; i < 8; ++i) {
            const float angle = static_cast<float>(i) * 0.78539816f;
            const float inner = core + thin;
            const float ray = outer + thin;
            setColor(renderer, primary.r, primary.g, primary.b, 255);
            SDL_RenderLine(renderer,
                           cx + std::cos(angle) * inner,
                           cy + std::sin(angle) * inner,
                           cx + std::cos(angle) * ray,
                           cy + std::sin(angle) * ray);
        }
        break;
    case 1:
        fillCircle(renderer, cx, cy, outer * 0.82f, primary);
        fillCircle(renderer, cx + outer * 0.34f, cy - outer * 0.08f, outer * 0.72f, background);
        break;
    case 2:
        fillCircle(renderer, cx - core, cy - core * 0.75f, core * 0.76f, primary);
        fillCircle(renderer, cx + core, cy - core * 0.75f, core * 0.76f, primary);
        fillCircle(renderer, cx - core, cy + core * 0.72f, core * 0.76f, primary);
        fillCircle(renderer, cx + core, cy + core * 0.72f, core * 0.76f, primary);
        fillRect(renderer, SDL_FRect{cx - thin * 0.5f, cy + core * 0.7f, thin, outer * 0.9f}, secondary.r, secondary.g, secondary.b);
        break;
    case 3:
        fillDiamond(renderer, cx, cy, outer * 0.95f, outer * 1.08f, primary);
        fillDiamond(renderer, cx, cy, outer * 0.42f, outer * 0.5f, secondary);
        break;
    case 4:
        fillTriangle(renderer,
                     SDL_FPoint{cx, cy - outer * 1.08f},
                     SDL_FPoint{cx - outer * 0.66f, cy - outer * 0.05f},
                     SDL_FPoint{cx + outer * 0.66f, cy - outer * 0.05f},
                     primary);
        fillCircle(renderer, cx, cy + outer * 0.18f, outer * 0.68f, primary);
        fillCircle(renderer, cx - outer * 0.22f, cy - outer * 0.08f, outer * 0.18f, secondary);
        break;
    case 5:
        fillTriangle(renderer,
                     SDL_FPoint{cx - outer * 0.18f, cy - outer * 1.0f},
                     SDL_FPoint{cx + outer * 0.56f, cy - outer * 0.16f},
                     SDL_FPoint{cx + thin * 0.2f, cy - outer * 0.16f},
                     primary);
        fillTriangle(renderer,
                     SDL_FPoint{cx - outer * 0.56f, cy + outer * 0.1f},
                     SDL_FPoint{cx + outer * 0.18f, cy + outer * 0.1f},
                     SDL_FPoint{cx - outer * 0.2f, cy + outer * 1.0f},
                     primary);
        break;
    case 6:
        for (int i = 0; i < 6; ++i) {
            const float angle = static_cast<float>(i) * 1.04719755f;
            fillCircle(renderer, cx + std::cos(angle) * core * 1.35f, cy + std::sin(angle) * core * 1.35f, core * 0.75f, primary);
        }
        fillCircle(renderer, cx, cy, core * 0.8f, secondary);
        break;
    case 7:
        fillRect(renderer, SDL_FRect{cx - outer, cy + outer * 0.12f, outer * 2.0f, outer * 0.56f}, primary.r, primary.g, primary.b);
        fillTriangle(renderer,
                     SDL_FPoint{cx - outer, cy + outer * 0.18f},
                     SDL_FPoint{cx - outer * 0.5f, cy - outer * 0.9f},
                     SDL_FPoint{cx - outer * 0.08f, cy + outer * 0.18f},
                     primary);
        fillTriangle(renderer,
                     SDL_FPoint{cx - outer * 0.36f, cy + outer * 0.18f},
                     SDL_FPoint{cx, cy - outer * 1.02f},
                     SDL_FPoint{cx + outer * 0.36f, cy + outer * 0.18f},
                     primary);
        fillTriangle(renderer,
                     SDL_FPoint{cx + outer * 0.08f, cy + outer * 0.18f},
                     SDL_FPoint{cx + outer * 0.5f, cy - outer * 0.9f},
                     SDL_FPoint{cx + outer, cy + outer * 0.18f},
                     primary);
        fillCircle(renderer, cx, cy - outer * 0.25f, core * 0.22f, secondary);
        break;
    case 8:
        fillDiamond(renderer, cx, cy - thin * 0.3f, outer * 0.76f, outer * 1.05f, primary);
        fillTriangle(renderer,
                     SDL_FPoint{cx, cy + outer * 0.8f},
                     SDL_FPoint{cx - thin * 0.55f, cy + outer * 0.1f},
                     SDL_FPoint{cx + thin * 0.55f, cy + outer * 0.1f},
                     secondary);
        break;
    default:
        fillCircle(renderer, cx, cy, outer * 0.82f, primary);
        setColor(renderer, secondary.r, secondary.g, secondary.b, secondary.a);
        SDL_RenderLine(renderer, cx - outer * 1.05f, cy + thin, cx + outer * 1.05f, cy - thin);
        SDL_RenderLine(renderer, cx - outer * 0.95f, cy + thin * 2.0f, cx + outer * 0.95f, cy);
        fillCircle(renderer, cx - outer * 0.18f, cy - outer * 0.1f, core * 0.25f, secondary);
        break;
    }
}

float debugTextWidth(const std::string& value) {
    return static_cast<float>(value.size()) * 8.0f;
}

float uiTextWidth(const std::string& value, float scale = 1.15f) {
    return debugTextWidth(value) * scale;
}

void uiText(SDL_Renderer* renderer, float x, float y, const std::string& value, float scale = 1.15f) {
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

bool pointInRect(float x, float y, const SDL_FRect& rect) {
    return x >= rect.x && x <= rect.x + rect.w && y >= rect.y && y <= rect.y + rect.h;
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

void drawButton(SDL_Renderer* renderer, const SDL_FRect& rect, const std::string& label) {
    fillRect(renderer, rect, 228, 179, 70);
    strokeRect(renderer, rect, 63, 45, 26);
    setColor(renderer, 25, 25, 25);
    uiText(renderer, rect.x + rect.w * 0.5f - uiTextWidth(label, 1.08f) * 0.5f, rect.y + 10.0f, label, 1.08f);
}

void spawnFireworkBurst(App& app, float x, float y) {
    static const std::array<SDL_Color, 5> palette{{
        SDL_Color{255, 209, 102, 255},
        SDL_Color{255, 111, 105, 255},
        SDL_Color{104, 214, 255, 255},
        SDL_Color{125, 211, 252, 255},
        SDL_Color{52, 211, 153, 255},
    }};
    for (int i = 0; i < 22; ++i) {
        const float angle = (static_cast<float>(i) / 22.0f) * 6.283185307f;
        const float speed = 44.0f + static_cast<float>((i % 6) * 8);
        const SDL_Color color = palette[static_cast<std::size_t>(i) % palette.size()];
        app.fireworks.push_back(FireworkParticle{
            SDL_FPoint{x, y},
            SDL_FPoint{std::cos(angle) * speed, std::sin(angle) * speed - 20.0f},
            0.0f,
            1.0f,
            color.r,
            color.g,
            color.b,
        });
    }
}

std::string formatTime(int totalSeconds) {
    const int minutes = totalSeconds / 60;
    const int seconds = totalSeconds % 60;
    auto two = [](int value) {
        return value < 10 ? std::string{"0"} + std::to_string(value) : std::to_string(value);
    };
    return two(minutes) + ":" + two(seconds);
}

void layoutCards(App& app) {
    const LevelConfig level = kLevels[static_cast<std::size_t>(app.levelIndex)];
    const float gap = level.size >= 8 ? 4.0f : 6.0f;
    const float gridW = static_cast<float>(level.size * level.cell) + static_cast<float>(level.size - 1) * gap;
    const float gridH = static_cast<float>(level.size * level.cell) + static_cast<float>(level.size - 1) * gap;
    const float startX = (kBaseWidth - gridW) * 0.5f;
    constexpr float headerBottom = 110.0f;
    constexpr float footerInset = 42.0f;
    const float playableHeight = kBaseHeight - headerBottom - footerInset;
    const float startY = headerBottom + std::max(0.0f, (playableHeight - gridH) * 0.5f);
    for (std::size_t i = 0; i < app.cards.size(); ++i) {
        const int row = static_cast<int>(i) / level.size;
        const int col = static_cast<int>(i) % level.size;
        app.cards[i].rect = SDL_FRect{
            startX + static_cast<float>(col) * (level.cell + gap),
            startY + static_cast<float>(row) * (level.cell + gap),
            static_cast<float>(level.cell),
            static_cast<float>(level.cell),
        };
    }
}

void startLevel(App& app, int levelIndex) {
    app.levelIndex = levelIndex;
    app.selectedIds.clear();
    app.fireworks.clear();
    app.mismatchDelay = -1.0f;
    app.pendingMismatchA = -1;
    app.pendingMismatchB = -1;
    app.moves = 0;
    app.timer = 0.0f;
    app.elapsed = 0.0f;
    app.started = false;
    app.won = false;
    app.locked = false;
    app.winSoundPlayed = false;
    clearEmojiCache(app);

    const LevelConfig level = kLevels[static_cast<std::size_t>(levelIndex)];
    const int pairCount = (level.size * level.size) / 2;
    std::vector<int> artIds;
    artIds.reserve(static_cast<std::size_t>(pairCount * 2));
    for (int i = 0; i < pairCount; ++i) {
        artIds.push_back(i);
        artIds.push_back(i);
    }
    std::shuffle(artIds.begin(), artIds.end(), app.rng);

    app.cards.clear();
    app.cards.reserve(artIds.size());
    for (std::size_t i = 0; i < artIds.size(); ++i) {
        app.cards.push_back(MemoryCard{static_cast<int>(i), artIds[i], false, false, 0.0f, {}});
    }
    layoutCards(app);
}

void updateApp(App& app, float delta) {
    app.elapsed += delta;
    if (app.started && !app.won && !app.locked) {
        app.timer += delta;
    }

    for (MemoryCard& card : app.cards) {
        const float target = (card.flipped || card.matched) ? 1.0f : 0.0f;
        if (card.flip < target) {
            card.flip = std::min(target, card.flip + delta * kFlipSpeed);
        } else if (card.flip > target) {
            card.flip = std::max(target, card.flip - delta * kFlipSpeed);
        }
    }

    if (app.mismatchDelay >= 0.0f) {
        app.mismatchDelay -= delta;
        if (app.mismatchDelay <= 0.0f) {
            for (MemoryCard& card : app.cards) {
                if (card.id == app.pendingMismatchA || card.id == app.pendingMismatchB) {
                    card.flipped = false;
                }
            }
            app.pendingMismatchA = -1;
            app.pendingMismatchB = -1;
            app.locked = false;
        }
    }

    if (!app.won) {
        const bool allMatched = std::all_of(app.cards.begin(), app.cards.end(), [](const MemoryCard& card) {
            return card.matched;
        });
        if (allMatched) {
            app.won = true;
            app.fireworkSpawnTimer = 0.0f;
            if (!app.winSoundPlayed) {
                playSound(app, SoundEffect::WinCongrat);
                app.winSoundPlayed = true;
            }
        }
    } else {
        app.fireworkSpawnTimer -= delta;
        if (app.fireworkSpawnTimer <= 0.0f) {
            std::uniform_real_distribution<float> xDist(80.0f, kBaseWidth - 80.0f);
            std::uniform_real_distribution<float> yDist(120.0f, 320.0f);
            spawnFireworkBurst(app, xDist(app.rng), yDist(app.rng));
            app.fireworkSpawnTimer = 0.34f;
        }
    }

    for (std::size_t i = 0; i < app.fireworks.size();) {
        app.fireworks[i].elapsed += delta;
        if (app.fireworks[i].elapsed >= app.fireworks[i].duration) {
            app.fireworks.erase(app.fireworks.begin() + static_cast<std::ptrdiff_t>(i));
        } else {
            ++i;
        }
    }

    cleanupFinishedAudioStreams(app);
}

void drawFireworks(App& app) {
    for (const FireworkParticle& particle : app.fireworks) {
        const float t = std::clamp(particle.elapsed / particle.duration, 0.0f, 1.0f);
        const float alpha = 1.0f - t;
        const SDL_FPoint pos{
            particle.position.x + particle.velocity.x * particle.elapsed,
            particle.position.y + particle.velocity.y * particle.elapsed + 22.0f * particle.elapsed * particle.elapsed,
        };
        fillRect(app.renderer, SDL_FRect{pos.x, pos.y, 3.0f, 3.0f}, particle.r, particle.g, particle.b,
                 static_cast<std::uint8_t>(220.0f * alpha));
    }
}

void drawApp(App& app) {
    SDL_SetRenderLogicalPresentation(app.renderer, kBaseWidth, kBaseHeight, SDL_LOGICAL_PRESENTATION_LETTERBOX);
    fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 18, 72, 94);
    fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, 98.0f}, 12, 49, 64);

    app.backRect = SDL_FRect{18.0f, 18.0f, 92.0f, 34.0f};
    app.restartRect = SDL_FRect{kBaseWidth - 118.0f, 18.0f, 100.0f, 34.0f};
    drawButton(app.renderer, app.backRect, "Lobby");
    drawButton(app.renderer, app.restartRect, "Restart");

    setColor(app.renderer, 243, 239, 225);
    const LevelConfig level = kLevels[static_cast<std::size_t>(app.levelIndex)];
    const std::string title = "Memory Cards";
    uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(title, 1.3f) * 0.5f, 18.0f, title, 1.3f);
    uiText(app.renderer, 18.0f, 64.0f, std::string{"Lv "} + std::to_string(app.levelIndex + 1) + "  " + std::to_string(level.size) + "x" + std::to_string(level.size));
    uiText(app.renderer, 168.0f, 64.0f, std::string{"Moves "} + std::to_string(app.moves));
    uiText(app.renderer, 318.0f, 64.0f, std::string{"Time "} + formatTime(static_cast<int>(app.timer)));

    for (const MemoryCard& card : app.cards) {
        const float flipScale = std::max(kMinFlipScale, std::fabs(std::cos(card.flip * 3.14159265f)));
        SDL_FRect drawRect = card.rect;
        drawRect.w = card.rect.w * flipScale;
        drawRect.x = card.rect.x + (card.rect.w - drawRect.w) * 0.5f;
        const bool showFront = card.flip >= 0.5f || card.matched;
        if (showFront) {
            const SDL_Color faceFill = card.matched ? SDL_Color{225, 243, 235, 255} : SDL_Color{244, 234, 216, 255};
            const SDL_Color faceBorder = card.matched ? SDL_Color{126, 164, 145, 255} : SDL_Color{120, 87, 62, 255};
            fillRect(app.renderer, drawRect, faceFill.r, faceFill.g, faceFill.b);
            fillRect(app.renderer, insetRect(drawRect, 4.0f),
                     static_cast<std::uint8_t>(std::min(255, faceFill.r + 8)),
                     static_cast<std::uint8_t>(std::min(255, faceFill.g + 8)),
                     static_cast<std::uint8_t>(std::min(255, faceFill.b + 8)));
            strokeRect(app.renderer, drawRect, faceBorder.r, faceBorder.g, faceBorder.b);
            if (card.matched) {
                fillRect(app.renderer, SDL_FRect{drawRect.x + 4.0f, drawRect.y + 4.0f, std::max(0.0f, drawRect.w - 8.0f), 6.0f}, 255, 255, 255, 64);
            }
            if (EmojiTexture* emoji = getEmojiTexture(app, card.artId)) {
                const float maxW = drawRect.w - 10.0f;
                const float maxH = drawRect.h - 10.0f;
                const float textureScale = std::min(maxW / static_cast<float>(emoji->width), maxH / static_cast<float>(emoji->height));
                const float renderedW = static_cast<float>(emoji->width) * textureScale;
                const float renderedH = static_cast<float>(emoji->height) * textureScale;
                const SDL_FRect emojiRect{
                    drawRect.x + (drawRect.w - renderedW) * 0.5f,
                    drawRect.y + (drawRect.h - renderedH) * 0.5f,
                    renderedW,
                    renderedH,
                };
                SDL_RenderTexture(app.renderer, emoji->texture, nullptr, &emojiRect);
            } else {
                drawCardIcon(app.renderer, insetRect(drawRect, 6.0f), card.artId, faceFill);
            }
        } else {
            drawCardBack(app.renderer, drawRect);
        }
    }

    if (app.won) {
        fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 6, 9, 20, 150);
        const SDL_FRect panel{60.0f, 274.0f, 360.0f, 200.0f};
        fillRect(app.renderer, panel, 242, 234, 207, 245);
        strokeRect(app.renderer, panel, 72, 55, 34);
        const bool isLastLevel = app.levelIndex == static_cast<int>(kLevels.size()) - 1;
        const std::string winTitle = isLastLevel ? "You beat all levels!" : "Level clear!";
        const std::string statText = std::to_string(app.moves) + " moves  " + formatTime(static_cast<int>(app.timer));
        setColor(app.renderer, 35, 31, 24);
        uiText(app.renderer, panel.x + panel.w * 0.5f - uiTextWidth(winTitle, 1.25f) * 0.5f, panel.y + 26.0f, winTitle, 1.25f);
        uiText(app.renderer, panel.x + panel.w * 0.5f - uiTextWidth(statText) * 0.5f, panel.y + 62.0f, statText);
        app.modalNextRect = SDL_FRect{panel.x + 40.0f, panel.y + 128.0f, 128.0f, 38.0f};
        app.modalRestartRect = SDL_FRect{panel.x + panel.w - 168.0f, panel.y + 128.0f, 128.0f, 38.0f};
        if (!isLastLevel) {
            drawButton(app.renderer, app.modalNextRect, "Next Level");
        } else {
            app.modalNextRect = SDL_FRect{0, 0, 0, 0};
        }
        drawButton(app.renderer, app.modalRestartRect, isLastLevel ? "Play Again" : "Restart");
        drawFireworks(app);
    }

    SDL_RenderPresent(app.renderer);
}

void handleCardClick(App& app, int id) {
    if (app.locked || app.won) return;
    auto it = std::find_if(app.cards.begin(), app.cards.end(), [id](const MemoryCard& card) { return card.id == id; });
    if (it == app.cards.end() || it->flipped || it->matched) return;

    if (!app.started) app.started = true;
    it->flipped = true;
    app.selectedIds.push_back(id);
    if (app.selectedIds.size() < 2) return;

    app.moves += 1;
    MemoryCard* first = nullptr;
    MemoryCard* second = nullptr;
    for (MemoryCard& card : app.cards) {
        if (card.id == app.selectedIds[0]) first = &card;
        if (card.id == app.selectedIds[1]) second = &card;
    }
    if (!first || !second) {
        app.selectedIds.clear();
        return;
    }
    if (first->artId == second->artId) {
        first->matched = true;
        second->matched = true;
    } else {
        app.locked = true;
        app.pendingMismatchA = first->id;
        app.pendingMismatchB = second->id;
        app.mismatchDelay = 0.9f;
    }
    app.selectedIds.clear();
}

bool init(App& app, const AppWindowState& initialWindowState) {
    SDL_SetAppMetadata("Memory Cards", "0.1.0", "com.gamestudio.memorycards");
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO)) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return false;
    }
    if (!TTF_Init()) {
        SDL_Log("TTF_Init failed: %s", SDL_GetError());
    }
    app.window = SDL_CreateWindow("Memory Cards", kBaseWidth, kBaseHeight, SDL_WINDOW_RESIZABLE);
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
    app.audioDevice = SDL_OpenAudioDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, nullptr);
    if (!app.audioDevice) {
        SDL_Log("SDL_OpenAudioDevice failed: %s", SDL_GetError());
    } else {
        SDL_ResumeAudioDevice(app.audioDevice);
    }
    g_soundAssetRoot = findSoundAssetRoot();
    if (g_soundAssetRoot.empty()) {
        SDL_Log("Memory Cards sound asset root not found. Audio disabled.");
        app.audioEnabled = false;
    }
    app.emojiFont = loadEmojiFont();
    startLevel(app, 0);
    return true;
}

void shutdown(App& app) {
    clearEmojiCache(app);
    for (SDL_AudioStream* stream : app.activeAudioStreams) {
        SDL_DestroyAudioStream(stream);
    }
    app.activeAudioStreams.clear();
    releaseLoadedSounds();
    if (app.emojiFont) TTF_CloseFont(app.emojiFont);
    if (app.audioDevice) SDL_CloseAudioDevice(app.audioDevice);
    if (app.renderer) SDL_DestroyRenderer(app.renderer);
    if (app.window) SDL_DestroyWindow(app.window);
    if (TTF_WasInit()) TTF_Quit();
    SDL_Quit();
}

void handlePointerDown(App& app, float x, float y) {
    if (pointInRect(x, y, app.backRect)) {
        playSound(app, SoundEffect::UiTap);
        app.exitAction = MemoryCardsExitAction::BackToLobby;
        app.running = false;
        return;
    }
    if (pointInRect(x, y, app.restartRect)) {
        playSound(app, SoundEffect::UiTap);
        startLevel(app, app.levelIndex);
        return;
    }
    if (app.won) {
        if (app.modalNextRect.w > 0.0f && pointInRect(x, y, app.modalNextRect)) {
            playSound(app, SoundEffect::UiTap);
            startLevel(app, std::min(app.levelIndex + 1, static_cast<int>(kLevels.size()) - 1));
            return;
        }
        if (pointInRect(x, y, app.modalRestartRect)) {
            playSound(app, SoundEffect::UiTap);
            startLevel(app, app.levelIndex == static_cast<int>(kLevels.size()) - 1 ? 0 : app.levelIndex);
            return;
        }
    }
    for (const MemoryCard& card : app.cards) {
        if (pointInRect(x, y, card.rect)) {
            if (!card.flipped && !card.matched && !app.locked && !app.won) {
                playSound(app, SoundEffect::UiTap);
            }
            handleCardClick(app, card.id);
            return;
        }
    }
}

}  // namespace

MemoryCardsRunResult runMemoryCardsApp(const AppWindowState& initialWindowState) {
    App app;
    if (!init(app, initialWindowState)) {
        shutdown(app);
        return MemoryCardsRunResult{MemoryCardsExitAction::Quit, initialWindowState};
    }

    std::uint64_t lastTicks = SDL_GetTicks();
    while (app.running) {
        const std::uint64_t nowTicks = SDL_GetTicks();
        const float delta = static_cast<float>(nowTicks - lastTicks) / 1000.0f;
        lastTicks = nowTicks;

        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                app.exitAction = MemoryCardsExitAction::Quit;
                app.running = false;
            } else if (event.type == SDL_EVENT_KEY_DOWN) {
                if (event.key.key == SDLK_ESCAPE) {
                    app.exitAction = MemoryCardsExitAction::Quit;
                    app.running = false;
                }
                if (event.key.key == SDLK_R) {
                    startLevel(app, app.levelIndex);
                }
            } else if (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN) {
                const SDL_FPoint logical = windowToLogical(app.renderer, event.button.x, event.button.y);
                handlePointerDown(app, logical.x, logical.y);
            } else if (event.type == SDL_EVENT_FINGER_DOWN) {
                int outW = 0;
                int outH = 0;
                SDL_GetRenderOutputSize(app.renderer, &outW, &outH);
                const SDL_FPoint logical = windowToLogical(app.renderer,
                                                           event.tfinger.x * static_cast<float>(outW),
                                                           event.tfinger.y * static_cast<float>(outH));
                handlePointerDown(app, logical.x, logical.y);
            }
        }

        updateApp(app, delta);
        drawApp(app);
        SDL_Delay(16);
    }

    app.windowState = snapshotWindowState(app.window);
    const MemoryCardsRunResult result{app.exitAction, app.windowState};
    shutdown(app);
    return result;
}