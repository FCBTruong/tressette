#include "flappy_bird_game.h"

#include <SDL3/SDL.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <random>
#include <string>
#include <vector>

namespace {

constexpr int kBaseWidth = 480;
constexpr int kBaseHeight = 854;
constexpr float kBirdX = 132.0f;
constexpr float kBirdRadius = 18.0f;
constexpr float kPipeWidth = 82.0f;
constexpr float kPipeGap = 214.0f;
constexpr float kPipeSpeed = 198.0f;
constexpr float kGravity = 1520.0f;
constexpr float kFlapVelocity = -448.0f;
constexpr float kGroundY = 766.0f;

struct PipePair {
    float x = 0.0f;
    float gapY = 0.0f;
    bool scored = false;
};

struct Cloud {
    float x = 0.0f;
    float y = 0.0f;
    float width = 0.0f;
    float speed = 0.0f;
};

struct App {
    SDL_Window* window = nullptr;
    SDL_Renderer* renderer = nullptr;
    std::mt19937 rng{std::random_device{}()};
    std::vector<PipePair> pipes;
    std::vector<Cloud> clouds;
    SDL_FRect backRect{};
    SDL_FRect pauseRect{};
    SDL_FRect overlayContinueRect{};
    SDL_FRect overlayRestartRect{};
    float elapsed = 0.0f;
    float birdY = kBaseHeight * 0.45f;
    float birdVelocity = 0.0f;
    float spawnTimer = 1.05f;
    float floorOffset = 0.0f;
    float resumeCountdown = 0.0f;
    int score = 0;
    int highScore = 0;
    bool started = false;
    bool gameOver = false;
    bool paused = false;
    bool running = true;
    FlappyBirdExitAction exitAction = FlappyBirdExitAction::Quit;
    AppWindowState windowState{};
    std::filesystem::path highScorePath;
};

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

float uiTextWidth(const std::string& value, float scale = 1.12f) {
    return debugTextWidth(value) * scale;
}

void uiText(SDL_Renderer* renderer, float x, float y, const std::string& value, float scale = 1.12f) {
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

std::filesystem::path legacyHighScorePath() {
    return std::filesystem::current_path() / "save" / "flappy_high_score.txt";
}

std::filesystem::path findHighScorePath() {
    char* prefPath = SDL_GetPrefPath("GameStudio", "Tressette");
    if (!prefPath) {
        return legacyHighScorePath();
    }

    const std::filesystem::path path = std::filesystem::path{prefPath} / "flappy_high_score.txt";
    SDL_free(prefPath);
    return path;
}

int loadHighScore(const std::filesystem::path& path) {
    std::ifstream input(path);
    int value = 0;
    if (input >> value) {
        return std::max(0, value);
    }
    return 0;
}

void saveHighScore(const App& app) {
    if (app.highScorePath.empty()) {
        return;
    }
    std::error_code ec;
    if (!app.highScorePath.parent_path().empty()) {
        std::filesystem::create_directories(app.highScorePath.parent_path(), ec);
    }
    std::ofstream output(app.highScorePath, std::ios::trunc);
    if (output) {
        output << app.highScore;
    }
}

int loadHighScoreWithLegacyMigration(const std::filesystem::path& path) {
    const int currentValue = loadHighScore(path);
    const std::filesystem::path legacyPath = legacyHighScorePath();
    if (path == legacyPath) {
        return currentValue;
    }

    const int legacyValue = loadHighScore(legacyPath);
    if (legacyValue > currentValue) {
        return legacyValue;
    }
    return currentValue;
}

void seedClouds(App& app) {
    app.clouds = {
        {44.0f, 154.0f, 88.0f, 16.0f},
        {198.0f, 112.0f, 64.0f, 24.0f},
        {340.0f, 176.0f, 102.0f, 20.0f},
        {418.0f, 132.0f, 56.0f, 28.0f},
        {120.0f, 228.0f, 74.0f, 18.0f},
    };
}

void resetRound(App& app) {
    app.pipes.clear();
    app.birdY = kBaseHeight * 0.45f;
    app.birdVelocity = 0.0f;
    app.spawnTimer = 1.05f;
    app.floorOffset = 0.0f;
    app.resumeCountdown = 0.0f;
    app.score = 0;
    app.started = false;
    app.gameOver = false;
    app.paused = false;
    app.elapsed = 0.0f;
    seedClouds(app);
}

void drawButtonBase(SDL_Renderer* renderer, const SDL_FRect& rect, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    fillRect(renderer, rect, r, g, b, 240);
    strokeRect(renderer, rect, 34, 46, 68, 255);
}

void drawBackIcon(SDL_Renderer* renderer, const SDL_FRect& rect) {
    const float cx = rect.x + rect.w * 0.5f;
    const float cy = rect.y + rect.h * 0.5f;
    setColor(renderer, 23, 25, 32, 255);
    SDL_RenderLine(renderer, cx + 8.0f, cy - 9.0f, cx - 4.0f, cy);
    SDL_RenderLine(renderer, cx - 4.0f, cy, cx + 8.0f, cy + 9.0f);
    SDL_RenderLine(renderer, cx - 2.0f, cy, cx + 14.0f, cy);
}

void drawPauseIcon(SDL_Renderer* renderer, const SDL_FRect& rect) {
    fillRect(renderer, SDL_FRect{rect.x + rect.w * 0.34f, rect.y + rect.h * 0.24f, rect.w * 0.1f, rect.h * 0.52f}, 23, 25, 32, 255);
    fillRect(renderer, SDL_FRect{rect.x + rect.w * 0.56f, rect.y + rect.h * 0.24f, rect.w * 0.1f, rect.h * 0.52f}, 23, 25, 32, 255);
}

void drawPlayIcon(SDL_Renderer* renderer, const SDL_FRect& rect) {
    setColor(renderer, 23, 25, 32, 255);
    const SDL_FPoint p1{rect.x + rect.w * 0.38f, rect.y + rect.h * 0.26f};
    const SDL_FPoint p2{rect.x + rect.w * 0.38f, rect.y + rect.h * 0.74f};
    const SDL_FPoint p3{rect.x + rect.w * 0.72f, rect.y + rect.h * 0.5f};
    for (int y = static_cast<int>(p1.y); y <= static_cast<int>(p2.y); ++y) {
        const float fy = static_cast<float>(y);
        float rightX = p3.x;
        if (fy <= p3.y) {
            const float topSpan = std::max(0.0001f, p3.y - p1.y);
            rightX = std::lerp(p1.x, p3.x, (fy - p1.y) / topSpan);
        } else {
            const float bottomSpan = std::max(0.0001f, p2.y - p3.y);
            rightX = std::lerp(p3.x, p2.x, (fy - p3.y) / bottomSpan);
        }
        SDL_RenderLine(renderer, p1.x, fy, rightX, fy);
    }
}

void drawRestartIcon(SDL_Renderer* renderer, const SDL_FRect& rect) {
    const float cx = rect.x + rect.w * 0.5f;
    const float cy = rect.y + rect.h * 0.54f;
    const float radius = std::min(rect.w, rect.h) * 0.22f;
    setColor(renderer, 23, 25, 32, 255);
    for (int i = 35; i <= 320; i += 8) {
        const float angleA = static_cast<float>(i) * 0.0174532925f;
        const float angleB = static_cast<float>(i + 8) * 0.0174532925f;
        SDL_RenderLine(renderer,
                       cx + std::cos(angleA) * radius,
                       cy + std::sin(angleA) * radius,
                       cx + std::cos(angleB) * radius,
                       cy + std::sin(angleB) * radius);
    }
    SDL_RenderLine(renderer, cx - radius * 0.28f, cy - radius * 1.02f, cx - radius * 0.92f, cy - radius * 0.82f);
    SDL_RenderLine(renderer, cx - radius * 0.28f, cy - radius * 1.02f, cx - radius * 0.48f, cy - radius * 0.36f);
}

void drawCloud(SDL_Renderer* renderer, const Cloud& cloud) {
    fillCircle(renderer, cloud.x, cloud.y, cloud.width * 0.24f, 255, 255, 255, 166);
    fillCircle(renderer, cloud.x + cloud.width * 0.24f, cloud.y - 8.0f, cloud.width * 0.2f, 255, 255, 255, 180);
    fillCircle(renderer, cloud.x + cloud.width * 0.48f, cloud.y, cloud.width * 0.26f, 255, 255, 255, 166);
    fillRect(renderer, SDL_FRect{cloud.x - cloud.width * 0.08f, cloud.y - 2.0f, cloud.width * 0.66f, cloud.width * 0.16f}, 255, 255, 255, 152);
}

void drawPipe(SDL_Renderer* renderer, const PipePair& pipe) {
    const SDL_FRect topRect{pipe.x, 0.0f, kPipeWidth, pipe.gapY - kPipeGap * 0.5f};
    const SDL_FRect bottomRect{pipe.x, pipe.gapY + kPipeGap * 0.5f, kPipeWidth, kGroundY - (pipe.gapY + kPipeGap * 0.5f)};
    const SDL_FRect topCap{pipe.x - 6.0f, topRect.h - 24.0f, kPipeWidth + 12.0f, 24.0f};
    const SDL_FRect bottomCap{pipe.x - 6.0f, bottomRect.y, kPipeWidth + 12.0f, 24.0f};

    fillRect(renderer, topRect, 67, 176, 102);
    fillRect(renderer, bottomRect, 67, 176, 102);
    fillRect(renderer, SDL_FRect{topRect.x + 8.0f, topRect.y, 12.0f, topRect.h}, 108, 214, 138, 180);
    fillRect(renderer, SDL_FRect{bottomRect.x + 8.0f, bottomRect.y, 12.0f, bottomRect.h}, 108, 214, 138, 180);
    fillRect(renderer, topCap, 53, 134, 80);
    fillRect(renderer, bottomCap, 53, 134, 80);
    strokeRect(renderer, topRect, 26, 90, 46);
    strokeRect(renderer, bottomRect, 26, 90, 46);
    strokeRect(renderer, topCap, 26, 90, 46);
    strokeRect(renderer, bottomCap, 26, 90, 46);
}

void drawBird(SDL_Renderer* renderer, float y, float rotation) {
    const float bob = std::sin(rotation) * 2.0f;
    fillCircle(renderer, kBirdX, y + bob, 19.0f, 255, 224, 87);
    fillCircle(renderer, kBirdX + 16.0f, y - 4.0f + bob, 8.5f, 248, 196, 62);
    fillCircle(renderer, kBirdX - 5.0f, y - 5.0f + bob, 7.5f, 255, 244, 198);
    fillCircle(renderer, kBirdX - 3.0f, y - 7.0f + bob, 2.6f, 34, 42, 58);
    fillCircle(renderer, kBirdX - 1.0f, y + 6.0f + bob, 11.0f, 246, 160, 66, 215);
    fillRect(renderer, SDL_FRect{kBirdX + 16.0f, y - 3.0f + bob, 16.0f, 8.0f}, 239, 118, 54);
    strokeRect(renderer, SDL_FRect{kBirdX + 16.0f, y - 3.0f + bob, 16.0f, 8.0f}, 184, 87, 28);
}

void updateHighScore(App& app) {
    if (app.score > app.highScore) {
        app.highScore = app.score;
        saveHighScore(app);
    }
}

void spawnPipe(App& app) {
    std::uniform_real_distribution<float> gapDist(224.0f, 572.0f);
    app.pipes.push_back(PipePair{kBaseWidth + 36.0f, gapDist(app.rng), false});
}

void hitGround(App& app) {
    app.gameOver = true;
    app.started = false;
    app.birdVelocity = 0.0f;
    app.birdY = std::min(app.birdY, kGroundY - kBirdRadius);
}

bool collidesWithPipe(const PipePair& pipe, float birdY) {
    const float birdLeft = kBirdX - kBirdRadius;
    const float birdRight = kBirdX + kBirdRadius;
    const float birdTop = birdY - kBirdRadius;
    const float birdBottom = birdY + kBirdRadius;
    if (birdRight < pipe.x || birdLeft > pipe.x + kPipeWidth) {
        return false;
    }
    const float gapTop = pipe.gapY - kPipeGap * 0.5f;
    const float gapBottom = pipe.gapY + kPipeGap * 0.5f;
    return birdTop < gapTop || birdBottom > gapBottom;
}

void flap(App& app) {
    if (app.gameOver || app.paused || app.resumeCountdown > 0.0f) {
        return;
    }
    app.started = true;
    app.birdVelocity = kFlapVelocity;
}

void startResumeCountdown(App& app) {
    if (app.gameOver || !app.started) {
        return;
    }
    app.paused = false;
    app.resumeCountdown = 3.0f;
}

void togglePause(App& app) {
    if (!app.started || app.gameOver || app.resumeCountdown > 0.0f) {
        return;
    }
    app.paused = !app.paused;
}

void updateApp(App& app, float delta) {
    app.elapsed += delta;

    if (!app.paused && app.resumeCountdown <= 0.0f) {
        app.floorOffset = std::fmod(app.floorOffset + kPipeSpeed * delta, 48.0f);
        for (Cloud& cloud : app.clouds) {
            cloud.x -= cloud.speed * delta;
            if (cloud.x + cloud.width < -16.0f) {
                cloud.x = kBaseWidth + 20.0f;
            }
        }
    }

    if (app.resumeCountdown > 0.0f) {
        app.resumeCountdown = std::max(0.0f, app.resumeCountdown - delta);
        return;
    }

    if (!app.started || app.gameOver || app.paused) {
        if (!app.started && !app.gameOver) {
            app.birdY = kBaseHeight * 0.45f + std::sin(app.elapsed * 2.4f) * 8.0f;
        }
        return;
    }

    app.spawnTimer -= delta;
    if (app.spawnTimer <= 0.0f) {
        spawnPipe(app);
        app.spawnTimer = 1.4f;
    }

    app.birdVelocity += kGravity * delta;
    app.birdY += app.birdVelocity * delta;

    for (PipePair& pipe : app.pipes) {
        pipe.x -= kPipeSpeed * delta;
        if (!pipe.scored && pipe.x + kPipeWidth < kBirdX) {
            pipe.scored = true;
            ++app.score;
            updateHighScore(app);
        }
    }

    app.pipes.erase(
        std::remove_if(app.pipes.begin(), app.pipes.end(), [](const PipePair& pipe) {
            return pipe.x + kPipeWidth < -24.0f;
        }),
        app.pipes.end());

    if (app.birdY - kBirdRadius <= 0.0f || app.birdY + kBirdRadius >= kGroundY) {
        hitGround(app);
        return;
    }

    for (const PipePair& pipe : app.pipes) {
        if (collidesWithPipe(pipe, app.birdY)) {
            hitGround(app);
            return;
        }
    }
}

void drawApp(App& app) {
    SDL_SetRenderLogicalPresentation(app.renderer, kBaseWidth, kBaseHeight, SDL_LOGICAL_PRESENTATION_LETTERBOX);
    for (int i = 0; i < 24; ++i) {
        const float t = static_cast<float>(i) / 23.0f;
        const std::uint8_t r = static_cast<std::uint8_t>(std::lerp(114.0f, 28.0f, t));
        const std::uint8_t g = static_cast<std::uint8_t>(std::lerp(203.0f, 124.0f, t));
        const std::uint8_t b = static_cast<std::uint8_t>(std::lerp(250.0f, 210.0f, t));
        fillRect(app.renderer, SDL_FRect{0.0f, t * kBaseHeight, static_cast<float>(kBaseWidth), kBaseHeight / 23.0f + 2.0f}, r, g, b);
    }

    fillCircle(app.renderer, 388.0f, 150.0f, 54.0f, 255, 234, 158, 220);
    fillCircle(app.renderer, 388.0f, 150.0f, 78.0f, 255, 240, 196, 72);

    for (const Cloud& cloud : app.clouds) {
        drawCloud(app.renderer, cloud);
    }

    fillRect(app.renderer, SDL_FRect{0.0f, 586.0f, static_cast<float>(kBaseWidth), 152.0f}, 112, 191, 114);
    fillRect(app.renderer, SDL_FRect{0.0f, 630.0f, static_cast<float>(kBaseWidth), 116.0f}, 85, 163, 97);
    fillRect(app.renderer, SDL_FRect{0.0f, kGroundY, static_cast<float>(kBaseWidth), static_cast<float>(kBaseHeight) - kGroundY}, 214, 188, 104);
    fillRect(app.renderer, SDL_FRect{0.0f, kGroundY - 12.0f, static_cast<float>(kBaseWidth), 12.0f}, 149, 209, 81);
    for (int i = -1; i < 14; ++i) {
        const float x = static_cast<float>(i) * 48.0f - app.floorOffset;
        fillRect(app.renderer, SDL_FRect{x, kGroundY + 14.0f, 22.0f, 10.0f}, 190, 160, 77);
        fillRect(app.renderer, SDL_FRect{x + 24.0f, kGroundY + 30.0f, 18.0f, 10.0f}, 198, 167, 84);
    }

    for (const PipePair& pipe : app.pipes) {
        drawPipe(app.renderer, pipe);
    }

    app.backRect = SDL_FRect{18.0f, 18.0f, 42.0f, 42.0f};
    app.pauseRect = SDL_FRect{kBaseWidth - 60.0f, 18.0f, 42.0f, 42.0f};
    drawButtonBase(app.renderer, app.backRect, 250, 225, 149);
    drawBackIcon(app.renderer, app.backRect);
    drawButtonBase(app.renderer, app.pauseRect, 171, 226, 172);
    if (app.paused || app.resumeCountdown > 0.0f) {
        drawPlayIcon(app.renderer, app.pauseRect);
    } else {
        drawPauseIcon(app.renderer, app.pauseRect);
    }

    setColor(app.renderer, 255, 250, 237, 255);
    const std::string title = "Flappy Bird";
    uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(title, 1.34f) * 0.5f, 18.0f, title, 1.34f);
    uiText(app.renderer, 20.0f, 66.0f, std::string{"Score "} + std::to_string(app.score), 1.06f);
    uiText(app.renderer, 314.0f, 66.0f, std::string{"Best "} + std::to_string(app.highScore), 1.06f);

    const float rotation = std::clamp(app.birdVelocity / 520.0f, -0.9f, 1.2f);
    drawBird(app.renderer, app.birdY, rotation);

    if (!app.started && !app.gameOver) {
        fillRect(app.renderer, SDL_FRect{52.0f, 286.0f, 376.0f, 132.0f}, 15, 26, 36, 122);
        fillRect(app.renderer, SDL_FRect{58.0f, 292.0f, 364.0f, 120.0f}, 255, 255, 255, 18);
        strokeRect(app.renderer, SDL_FRect{58.0f, 292.0f, 364.0f, 120.0f}, 247, 233, 184, 176);
        setColor(app.renderer, 255, 245, 214, 255);
        uiText(app.renderer, 116.0f, 320.0f, "Tap to flap through pipes", 1.08f);
        uiText(app.renderer, 126.0f, 356.0f, "Beat your best score", 1.0f);
    }

    if (app.gameOver) {
        fillRect(app.renderer, SDL_FRect{42.0f, 246.0f, 396.0f, 214.0f}, 13, 21, 28, 168);
        fillRect(app.renderer, SDL_FRect{50.0f, 254.0f, 380.0f, 198.0f}, 255, 255, 255, 18);
        strokeRect(app.renderer, SDL_FRect{50.0f, 254.0f, 380.0f, 198.0f}, 251, 230, 174, 190);
        setColor(app.renderer, 255, 245, 214, 255);
        uiText(app.renderer, 152.0f, 284.0f, "Round Over", 1.3f);
        uiText(app.renderer, 122.0f, 332.0f, std::string{"Score  "} + std::to_string(app.score), 1.06f);
        uiText(app.renderer, 122.0f, 364.0f, std::string{"High   "} + std::to_string(app.highScore), 1.06f);
        app.overlayRestartRect = SDL_FRect{196.0f, 392.0f, 88.0f, 52.0f};
        drawButtonBase(app.renderer, app.overlayRestartRect, 250, 211, 108);
        drawRestartIcon(app.renderer, app.overlayRestartRect);
    }

    if (app.paused) {
        fillRect(app.renderer, SDL_FRect{0.0f, 0.0f, static_cast<float>(kBaseWidth), static_cast<float>(kBaseHeight)}, 10, 16, 24, 118);
        fillRect(app.renderer, SDL_FRect{106.0f, 276.0f, 268.0f, 170.0f}, 13, 21, 28, 172);
        fillRect(app.renderer, SDL_FRect{114.0f, 284.0f, 252.0f, 154.0f}, 255, 255, 255, 18);
        strokeRect(app.renderer, SDL_FRect{114.0f, 284.0f, 252.0f, 154.0f}, 251, 230, 174, 190);
        fillRect(app.renderer, SDL_FRect{208.0f, 314.0f, 16.0f, 46.0f}, 255, 240, 196, 220);
        fillRect(app.renderer, SDL_FRect{256.0f, 314.0f, 16.0f, 46.0f}, 255, 240, 196, 220);
        app.overlayContinueRect = SDL_FRect{192.0f, 380.0f, 96.0f, 42.0f};
        drawButtonBase(app.renderer, app.overlayContinueRect, 171, 226, 172);
        drawPlayIcon(app.renderer, app.overlayContinueRect);
    }

    if (app.resumeCountdown > 0.0f) {
        const int countdownValue = static_cast<int>(std::ceil(app.resumeCountdown));
        fillRect(app.renderer, SDL_FRect{0.0f, 0.0f, static_cast<float>(kBaseWidth), static_cast<float>(kBaseHeight)}, 10, 16, 24, 72);
        fillCircle(app.renderer, kBaseWidth * 0.5f, kBaseHeight * 0.44f, 76.0f, 12, 20, 30, 180);
        strokeRect(app.renderer, SDL_FRect{kBaseWidth * 0.5f - 76.0f, kBaseHeight * 0.44f - 76.0f, 152.0f, 152.0f}, 251, 230, 174, 128);
        setColor(app.renderer, 255, 245, 214, 255);
        uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(std::to_string(countdownValue), 2.2f) * 0.5f, kBaseHeight * 0.44f - 22.0f, std::to_string(countdownValue), 2.2f);
    }

    SDL_RenderPresent(app.renderer);
}

void shutdown(App& app) {
    if (app.renderer) {
        SDL_DestroyRenderer(app.renderer);
    }
    if (app.window) {
        SDL_DestroyWindow(app.window);
    }
    SDL_Quit();
}

bool init(App& app, const AppWindowState& initialWindowState) {
    SDL_SetAppMetadata("Flappy Bird", "0.1.0", "com.gamestudio.flappybird");
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return false;
    }
    app.window = SDL_CreateWindow("Flappy Bird", kBaseWidth, kBaseHeight, SDL_WINDOW_RESIZABLE);
    if (!app.window) {
        SDL_Log("SDL_CreateWindow failed: %s", SDL_GetError());
        return false;
    }
    app.renderer = SDL_CreateRenderer(app.window, nullptr);
    if (!app.renderer) {
        SDL_Log("SDL_CreateRenderer failed: %s", SDL_GetError());
        return false;
    }
    SDL_SetRenderVSync(app.renderer, 1);
    SDL_SetRenderDrawBlendMode(app.renderer, SDL_BLENDMODE_BLEND);
    applyWindowState(app.window, initialWindowState);
    app.highScorePath = findHighScorePath();
    app.highScore = loadHighScoreWithLegacyMigration(app.highScorePath);
    saveHighScore(app);
    resetRound(app);
    return true;
}

void restartRound(App& app) {
    resetRound(app);
}

void handleTap(App& app, float x, float y) {
    if (pointInRect(x, y, app.backRect)) {
        app.exitAction = FlappyBirdExitAction::BackToLobby;
        app.running = false;
        return;
    }
    if (pointInRect(x, y, app.pauseRect)) {
        if (app.paused) {
            startResumeCountdown(app);
        } else {
            togglePause(app);
        }
        return;
    }
    if (app.paused) {
        if (pointInRect(x, y, app.overlayContinueRect)) {
            startResumeCountdown(app);
        }
        return;
    }
    if (app.resumeCountdown > 0.0f) {
        return;
    }
    if (app.gameOver) {
        if (pointInRect(x, y, app.overlayRestartRect)) {
            restartRound(app);
        }
        return;
    }
    flap(app);
}

}  // namespace

FlappyBirdRunResult runFlappyBirdApp(const AppWindowState& initialWindowState) {
    App app;
    if (!init(app, initialWindowState)) {
        shutdown(app);
        return FlappyBirdRunResult{FlappyBirdExitAction::Quit, initialWindowState};
    }

    std::uint64_t lastTicks = SDL_GetTicks();
    while (app.running) {
        const std::uint64_t nowTicks = SDL_GetTicks();
        const float delta = std::min(0.033f, static_cast<float>(nowTicks - lastTicks) / 1000.0f);
        lastTicks = nowTicks;

        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                app.exitAction = FlappyBirdExitAction::Quit;
                app.running = false;
            } else if (event.type == SDL_EVENT_KEY_DOWN) {
                if (event.key.key == SDLK_ESCAPE) {
                    app.exitAction = FlappyBirdExitAction::Quit;
                    app.running = false;
                } else if (event.key.key == SDLK_P) {
                    if (app.paused) {
                        startResumeCountdown(app);
                    } else {
                        togglePause(app);
                    }
                } else if (event.key.key == SDLK_SPACE || event.key.key == SDLK_UP) {
                    if (app.gameOver) {
                        restartRound(app);
                    } else if (app.paused) {
                        startResumeCountdown(app);
                    } else {
                        flap(app);
                    }
                } else if (event.key.key == SDLK_R) {
                    if (app.gameOver) {
                        restartRound(app);
                    }
                }
            } else if (event.type == SDL_EVENT_MOUSE_BUTTON_UP) {
                const SDL_FPoint logical = windowToLogical(app.renderer, event.button.x, event.button.y);
                handleTap(app, logical.x, logical.y);
            } else if (event.type == SDL_EVENT_FINGER_UP) {
                int outW = 0;
                int outH = 0;
                SDL_GetRenderOutputSize(app.renderer, &outW, &outH);
                const SDL_FPoint logical = windowToLogical(app.renderer,
                                                           event.tfinger.x * static_cast<float>(outW),
                                                           event.tfinger.y * static_cast<float>(outH));
                handleTap(app, logical.x, logical.y);
            }
        }

        updateApp(app, delta);
        drawApp(app);
        SDL_Delay(16);
    }

    app.windowState = snapshotWindowState(app.window);
    const FlappyBirdRunResult result{app.exitAction, app.windowState};
    shutdown(app);
    return result;
}
