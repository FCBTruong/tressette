#include "scopa_game.h"

#include <SDL3/SDL.h>
#include <SDL3_image/SDL_image.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <numeric>
#include <random>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

constexpr int kBaseWidth = 480;
constexpr int kBaseHeight = 854;
constexpr float kCardW = 62.0f;
constexpr float kCardH = 92.0f;
constexpr float kHandCardW = 74.0f;
constexpr float kHandCardH = 110.0f;
constexpr int kMatchTargetScore = 11;
constexpr float kBotHandY = 90.0f;
constexpr float kBotSummaryY = 186.0f;
constexpr float kTableZoneY = 250.0f;
constexpr float kTableZoneH = 220.0f;
constexpr float kStatusY = 548.0f;
constexpr float kCaptureOptionsY = 586.0f;
constexpr float kPlayerSummaryY = 640.0f;
constexpr float kPlayerHandY = 676.0f;
constexpr float kGlobalUiTextScale = 1.55f;

enum class Suit : int { Denari, Coppe, Spade, Bastoni };
enum class SoundEffect : int { Shuffle, Deal, Draw, Play, MyTurn, CompareWin, UiTap };
enum class GamePhase {
    InitRound,
    PlayerTurn,
    PlayerChooseCapture,
    BotTurn,
    RoundSummary,
    MatchOver,
};

struct Card {
    int id = -1;
    Suit suit = Suit::Denari;
    int rank = 1;
    int captureValue = 1;
    int primieraValue = 16;
};

struct LoadedSound {
    SDL_AudioSpec spec{};
    Uint8* data = nullptr;
    Uint32 length = 0;
};

struct DealFlight {
    Card card{};
    int lane = 0;
    SDL_FRect from{};
    SDL_FRect to{};
    float elapsed = 0.0f;
    float delay = 0.0f;
    float duration = 0.34f;
    bool faceUp = false;
};

struct PlayFlight {
    Card card{};
    SDL_FRect from{};
    SDL_FRect to{};
    float elapsed = 0.0f;
    float delay = 0.0f;
    float duration = 0.26f;
    float scaleFrom = 1.0f;
    float scaleTo = 1.0f;
    bool hideTableCard = false;
};

struct CaptureRay {
    SDL_FPoint from{};
    SDL_FPoint to{};
    float elapsed = 0.0f;
    float delay = 0.0f;
    float duration = 0.24f;
};

struct FireworkParticle {
    SDL_FPoint position{};
    SDL_FPoint velocity{};
    float elapsed = 0.0f;
    float duration = 1.0f;
    std::uint8_t r = 255;
    std::uint8_t g = 255;
    std::uint8_t b = 255;
};

struct CaptureOption {
    std::vector<int> tableIndices;
    std::string label;
    int capturedCount = 0;
    int denariCount = 0;
    int primieraGain = 0;
    bool takesSettebello = false;
};

struct PlayerState {
    std::vector<Card> hand;
    std::vector<Card> capturedCards;
    int scopaCount = 0;
    int matchScore = 0;
};

struct RoundScoreBreakdown {
    std::array<int, 2> carte{0, 0};
    std::array<int, 2> denari{0, 0};
    std::array<int, 2> settebello{0, 0};
    std::array<int, 2> primiera{0, 0};
    std::array<int, 2> scope{0, 0};
    std::array<int, 2> primieraScore{0, 0};
    std::array<int, 2> total{0, 0};
};

struct GameState {
    std::vector<Card> deck;
    std::vector<Card> tableCards;
    std::array<PlayerState, 2> players;
    RoundScoreBreakdown lastRoundScore{};
    GamePhase phase = GamePhase::InitRound;
    int currentTurn = 0;
    int dealer = 1;
    int starter = 0;
    int lastCapturer = -1;
    int roundNumber = 1;
    int selectedHandIndex = -1;
    int highlightedCaptureIndex = 0;
    int matchWinner = -1;
    std::vector<CaptureOption> validCaptures;
    bool roundOver = false;
    bool matchOver = false;
    std::string statusMessage = "Scopa";
};

struct App {
    SDL_Window* window = nullptr;
    SDL_Renderer* renderer = nullptr;
    SDL_AudioDeviceID audioDevice = 0;
    std::mt19937 rng{std::random_device{}()};
    GameState game;
    std::vector<DealFlight> dealFlights;
    std::vector<PlayFlight> playFlights;
    std::vector<CaptureRay> captureRays;
    std::vector<FireworkParticle> fireworkParticles;
    std::vector<SDL_AudioStream*> activeAudioStreams;
    std::vector<SDL_FRect> playerHandRects;
    std::vector<SDL_FRect> tableRects;
    std::vector<SDL_FRect> captureOptionRects;
    SDL_FRect menuRect{};
    SDL_FRect menuCloseRect{};
    SDL_FRect soundToggleRect{};
    SDL_FRect menuNewGameRect{};
    SDL_FRect menuLobbyRect{};
    SDL_FRect lobbyRect{};
    SDL_FRect newMatchRect{};
    SDL_FRect continueRect{};
    SDL_FRect overlayLobbyRect{};
    float time = 0.0f;
    float botDelay = -1.0f;
    float bannerTimer = 0.0f;
    float pauseForEffectTimer = 0.0f;
    float pendingHandDealTimer = 0.0f;
    float menuElapsed = 0.0f;
    std::array<int, 2> visibleHandCounts{0, 0};
    int visibleTableCount = 0;
    bool pendingHandDeal = false;
    bool dealing = false;
    bool menuOpen = false;
    bool audioEnabled = true;
    bool running = true;
    std::string bannerTitle;
    std::string bannerSubtitle;
    ScopaExitAction exitAction = ScopaExitAction::Quit;
    AppWindowState windowState{};
};

std::unordered_map<std::string, SDL_Texture*> g_textureCache;
std::unordered_map<int, LoadedSound> g_soundCache;
std::filesystem::path g_cardAssetRoot;
std::filesystem::path g_avatarAssetRoot;
std::filesystem::path g_soundAssetRoot;

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

void strokeCircle(SDL_Renderer* renderer, float cx, float cy, float radius, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    constexpr float kPi = 3.1415926535f;
    const int segments = std::max(24, static_cast<int>(radius * 3.2f));
    for (int i = 0; i < segments; ++i) {
        const float a0 = (static_cast<float>(i) / static_cast<float>(segments)) * kPi * 2.0f;
        const float a1 = (static_cast<float>(i + 1) / static_cast<float>(segments)) * kPi * 2.0f;
        SDL_RenderLine(renderer,
                       cx + std::cos(a0) * radius,
                       cy + std::sin(a0) * radius,
                       cx + std::cos(a1) * radius,
                       cy + std::sin(a1) * radius);
    }
}

float debugTextWidth(const std::string& value) {
    return static_cast<float>(value.size()) * 8.0f;
}

float uiTextWidth(const std::string& value, float scale = 1.1f) {
    return debugTextWidth(value) * scale * kGlobalUiTextScale;
}

void uiText(SDL_Renderer* renderer, float x, float y, const std::string& value, float scale = 1.1f) {
    const float actualScale = scale * kGlobalUiTextScale;
    const float invScale = 1.0f / actualScale;
    std::uint8_t r = 255;
    std::uint8_t g = 255;
    std::uint8_t b = 255;
    std::uint8_t a = 255;
    SDL_GetRenderDrawColor(renderer, &r, &g, &b, &a);
    SDL_SetRenderScale(renderer, actualScale, actualScale);
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

const char* suitShort(Suit suit) {
    switch (suit) {
    case Suit::Denari: return "D";
    case Suit::Coppe: return "C";
    case Suit::Spade: return "S";
    case Suit::Bastoni: return "B";
    }
    return "?";
}

std::string rankLabel(int rank) {
    if (rank == 1) return "A";
    if (rank == 8) return "F";
    if (rank == 9) return "C";
    if (rank == 10) return "R";
    return std::to_string(rank);
}

Suit suitFromId(int cardId) {
    return static_cast<Suit>(cardId % 4);
}

int rankFromId(int cardId) {
    return cardId / 4 + 1;
}

int primieraValueForRank(int rank) {
    switch (rank) {
    case 7: return 21;
    case 6: return 18;
    case 1: return 16;
    case 5: return 15;
    case 4: return 14;
    case 3: return 13;
    case 2: return 12;
    default: return 10;
    }
}

Card cardFromId(int cardId) {
    const int rank = rankFromId(cardId);
    return Card{cardId, suitFromId(cardId), rank, rank, primieraValueForRank(rank)};
}

std::string cardShortLabel(const Card& card) {
    return rankLabel(card.rank) + suitShort(card.suit);
}

std::filesystem::path findCardAssetRoot() {
#ifdef __ANDROID__
    return std::filesystem::path{"images/card_tressette"};
#else
    const std::array<std::filesystem::path, 4> candidates{
        std::filesystem::path{"../client/assets/images/card_tressette"},
        std::filesystem::path{"../../client/assets/images/card_tressette"},
        std::filesystem::path{"../../../client/assets/images/card_tressette"},
        std::filesystem::current_path() / "../client/assets/images/card_tressette",
    };

    for (const auto& candidate : candidates) {
        std::error_code ec;
        const auto full = std::filesystem::weakly_canonical(candidate, ec);
        const auto checkPath = ec ? candidate : full;
        if (std::filesystem::exists(checkPath / "card_back.png")) {
            return checkPath;
        }
    }
    return {};
#endif
}

std::filesystem::path cardTexturePath(int cardId) {
    return g_cardAssetRoot / "classic" / (std::to_string(cardId) + ".png");
}

std::filesystem::path cardBackTexturePath() {
    return g_cardAssetRoot / "card_back.png";
}

std::filesystem::path findAvatarAssetRoot() {
#ifdef __ANDROID__
    return std::filesystem::path{"images/avatars"};
#else
    const std::array<std::filesystem::path, 5> candidates{
        std::filesystem::path{"assets/images/avatars"},
        std::filesystem::path{"../client/assets/images/lobby/avatars"},
        std::filesystem::path{"../../client/assets/images/lobby/avatars"},
        std::filesystem::path{"../../../client/assets/images/lobby/avatars"},
        std::filesystem::current_path() / "../client/assets/images/lobby/avatars",
    };

    for (const auto& candidate : candidates) {
        std::error_code ec;
        const auto full = std::filesystem::weakly_canonical(candidate, ec);
        const auto checkPath = ec ? candidate : full;
        if (std::filesystem::exists(checkPath / "avatar_1.png")) {
            return checkPath;
        }
    }
    return {};
#endif
}

std::filesystem::path findSoundAssetRoot() {
#ifdef __ANDROID__
    return std::filesystem::path{"sounds"};
#else
    const std::array<std::filesystem::path, 5> candidates{
        std::filesystem::path{"assets/sounds"},
        std::filesystem::path{"../client_cpp/assets/sounds"},
        std::filesystem::path{"../client/assets/sounds"},
        std::filesystem::path{"../../client_cpp/assets/sounds"},
        std::filesystem::current_path() / "assets/sounds",
    };

    for (const auto& candidate : candidates) {
        std::error_code ec;
        const auto full = std::filesystem::weakly_canonical(candidate, ec);
        const auto checkPath = ec ? candidate : full;
        if (std::filesystem::exists(checkPath / "play_card.wav")) {
            return checkPath;
        }
    }
    return {};
#endif
}

std::filesystem::path avatarTexturePath(int player) {
    constexpr std::array<int, 4> avatarIds{1, 7, 13, 18};
    return g_avatarAssetRoot / ("avatar_" + std::to_string(avatarIds[static_cast<std::size_t>(player) % avatarIds.size()]) + ".png");
}

std::filesystem::path soundPath(SoundEffect effect) {
    switch (effect) {
    case SoundEffect::Shuffle: return g_soundAssetRoot / "shuffle_card_sound.wav";
    case SoundEffect::Deal: return g_soundAssetRoot / "deal_card_sound.wav";
    case SoundEffect::Draw: return g_soundAssetRoot / "flip_card.wav";
    case SoundEffect::Play: return g_soundAssetRoot / "play_card.wav";
    case SoundEffect::MyTurn: return g_soundAssetRoot / "your_turn_sound.wav";
    case SoundEffect::CompareWin: return g_soundAssetRoot / "win_turn_sound.wav";
    case SoundEffect::UiTap: return g_soundAssetRoot / "touch_sound.wav";
    }
    return {};
}

SDL_Texture* loadTexture(SDL_Renderer* renderer, const std::filesystem::path& path) {
    if (path.empty()) {
        return nullptr;
    }
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

void notifyMyTurn(App& app) {
    if (!app.dealing && app.game.phase == GamePhase::PlayerTurn) {
        playSound(app, SoundEffect::MyTurn);
    }
}

void showBanner(App& app, std::string title, std::string subtitle, float duration) {
    app.bannerTitle = std::move(title);
    app.bannerSubtitle = std::move(subtitle);
    app.bannerTimer = std::max(app.bannerTimer, duration);
}

void spawnFireworkBurst(App& app, float x, float y) {
    static const std::array<SDL_Color, 4> palette{{
        SDL_Color{255, 209, 102, 255},
        SDL_Color{255, 111, 105, 255},
        SDL_Color{104, 214, 255, 255},
        SDL_Color{199, 146, 255, 255},
    }};

    for (int i = 0; i < 18; ++i) {
        const float angle = (static_cast<float>(i) / 18.0f) * 6.283185307f;
        const float speed = 40.0f + static_cast<float>((i % 6) * 9);
        const SDL_Color color = palette[static_cast<std::size_t>(i) % palette.size()];
        app.fireworkParticles.push_back(FireworkParticle{
            SDL_FPoint{x, y},
            SDL_FPoint{std::cos(angle) * speed, std::sin(angle) * speed - 16.0f},
            0.0f,
            1.05f,
            color.r,
            color.g,
            color.b,
        });
    }
}

void drawFireworks(App& app) {
    for (const FireworkParticle& particle : app.fireworkParticles) {
        const float t = std::clamp(particle.elapsed / particle.duration, 0.0f, 1.0f);
        const float alphaFactor = 1.0f - t;
        const SDL_FPoint pos{
            particle.position.x + particle.velocity.x * particle.elapsed,
            particle.position.y + particle.velocity.y * particle.elapsed + 18.0f * particle.elapsed * particle.elapsed,
        };
        fillCircle(app.renderer, pos.x, pos.y, 2.4f, particle.r, particle.g, particle.b,
                   static_cast<std::uint8_t>(220.0f * alphaFactor));
    }
}

void destroyTextures() {
    for (auto& [_, texture] : g_textureCache) {
        if (texture) {
            SDL_DestroyTexture(texture);
        }
    }
    g_textureCache.clear();
}

std::vector<Card> makeDeck() {
    std::vector<Card> deck;
    deck.reserve(40);
    for (int id = 0; id < 40; ++id) {
        deck.push_back(cardFromId(id));
    }
    return deck;
}

int totalCardsInHands(const GameState& game) {
    return static_cast<int>(game.players[0].hand.size() + game.players[1].hand.size());
}

bool isFinalPlayOfRound(const GameState& game) {
    return game.deck.empty() && totalCardsInHands(game) == 1;
}

void shuffleDeck(std::vector<Card>& deck, std::mt19937& rng) {
    std::shuffle(deck.begin(), deck.end(), rng);
}

void dealCardsToPlayer(GameState& game, int player, int count) {
    for (int i = 0; i < count && !game.deck.empty(); ++i) {
        game.players[player].hand.push_back(game.deck.back());
        game.deck.pop_back();
    }
}

void sortHand(std::vector<Card>& hand) {
    std::sort(hand.begin(), hand.end(), [](const Card& a, const Card& b) {
        if (a.captureValue != b.captureValue) {
            return a.captureValue < b.captureValue;
        }
        return static_cast<int>(a.suit) < static_cast<int>(b.suit);
    });
}

void dealNextHands(GameState& game) {
    dealCardsToPlayer(game, 0, 3);
    dealCardsToPlayer(game, 1, 3);
    sortHand(game.players[0].hand);
    sortHand(game.players[1].hand);
}

void pushInitialTable(GameState& game) {
    for (int i = 0; i < 4 && !game.deck.empty(); ++i) {
        game.tableCards.push_back(game.deck.back());
        game.deck.pop_back();
    }
}

int countSuit(const std::vector<Card>& cards, Suit suit) {
    return static_cast<int>(std::count_if(cards.begin(), cards.end(), [suit](const Card& card) {
        return card.suit == suit;
    }));
}

bool hasCard(const std::vector<Card>& cards, Suit suit, int rank) {
    return std::any_of(cards.begin(), cards.end(), [suit, rank](const Card& card) {
        return card.suit == suit && card.rank == rank;
    });
}

int primieraScore(const std::vector<Card>& capturedCards, bool& eligible) {
    eligible = true;
    int total = 0;
    for (int suitIndex = 0; suitIndex < 4; ++suitIndex) {
        int best = -1;
        for (const Card& card : capturedCards) {
            if (static_cast<int>(card.suit) == suitIndex) {
                best = std::max(best, card.primieraValue);
            }
        }
        if (best < 0) {
            eligible = false;
            return 0;
        }
        total += best;
    }
    return total;
}

std::string joinCaptureLabel(const std::vector<Card>& cards) {
    std::string label;
    for (std::size_t i = 0; i < cards.size(); ++i) {
        if (i > 0) {
            label += "+";
        }
        label += cardShortLabel(cards[i]);
    }
    return label;
}

CaptureOption buildCaptureOption(const Card& playedCard, const std::vector<Card>& tableCards, const std::vector<int>& indices) {
    CaptureOption option;
    option.tableIndices = indices;
    option.capturedCount = static_cast<int>(indices.size()) + 1;
    option.denariCount = (playedCard.suit == Suit::Denari) ? 1 : 0;
    option.primieraGain = playedCard.primieraValue;
    option.takesSettebello = (playedCard.suit == Suit::Denari && playedCard.rank == 7);

    std::vector<Card> optionCards;
    optionCards.reserve(indices.size());
    for (int index : indices) {
        const Card& tableCard = tableCards[static_cast<std::size_t>(index)];
        optionCards.push_back(tableCard);
        option.denariCount += (tableCard.suit == Suit::Denari) ? 1 : 0;
        option.primieraGain += tableCard.primieraValue;
        if (tableCard.suit == Suit::Denari && tableCard.rank == 7) {
            option.takesSettebello = true;
        }
    }
    option.label = joinCaptureLabel(optionCards);
    return option;
}

std::vector<CaptureOption> getCaptureOptions(const Card& playedCard, const std::vector<Card>& tableCards) {
    std::vector<CaptureOption> options;
    std::vector<int> exactSingles;
    for (std::size_t i = 0; i < tableCards.size(); ++i) {
        if (tableCards[i].captureValue == playedCard.captureValue) {
            exactSingles.push_back(static_cast<int>(i));
        }
    }

    if (!exactSingles.empty()) {
        for (int index : exactSingles) {
            options.push_back(buildCaptureOption(playedCard, tableCards, {index}));
        }
        return options;
    }

    std::vector<int> current;
    auto dfs = [&](auto&& self, int startIndex, int remaining) -> void {
        if (remaining == 0 && !current.empty()) {
            options.push_back(buildCaptureOption(playedCard, tableCards, current));
            return;
        }
        if (remaining <= 0) {
            return;
        }
        for (int i = startIndex; i < static_cast<int>(tableCards.size()); ++i) {
            if (tableCards[static_cast<std::size_t>(i)].captureValue > remaining) {
                continue;
            }
            current.push_back(i);
            self(self, i + 1, remaining - tableCards[static_cast<std::size_t>(i)].captureValue);
            current.pop_back();
        }
    };

    dfs(dfs, 0, playedCard.captureValue);
    std::sort(options.begin(), options.end(), [](const CaptureOption& a, const CaptureOption& b) {
        if (a.capturedCount != b.capturedCount) {
            return a.capturedCount > b.capturedCount;
        }
        return a.label < b.label;
    });
    return options;
}

std::vector<Card> cardsFromIndices(const std::vector<Card>& cards, const std::vector<int>& indices) {
    std::vector<Card> result;
    result.reserve(indices.size());
    for (int index : indices) {
        result.push_back(cards[static_cast<std::size_t>(index)]);
    }
    return result;
}

float discardRiskScore(const GameState& game, const Card& card) {
    float penalty = 0.0f;
    if (card.suit == Suit::Denari) {
        penalty += 320.0f;
    }
    if (card.rank == 7) {
        penalty += 440.0f;
    }
    penalty += static_cast<float>(card.primieraValue) * 6.0f;
    const std::size_t futureTableSize = game.tableCards.size() + 1;
    if (futureTableSize <= 2) {
        penalty += 180.0f;
    }
    if (game.tableCards.empty()) {
        penalty += 120.0f;
    }
    return penalty;
}

struct BotMove {
    std::size_t handIndex = 0;
    int captureIndex = -1;
    float heuristic = -1000000.0f;
};

BotMove chooseBotMove(const GameState& game) {
    BotMove bestMove;
    const PlayerState& bot = game.players[1];
    const bool finalPlay = isFinalPlayOfRound(game);

    for (std::size_t handIndex = 0; handIndex < bot.hand.size(); ++handIndex) {
        const Card& card = bot.hand[handIndex];
        const auto options = getCaptureOptions(card, game.tableCards);
        if (options.empty()) {
            const float heuristic = -discardRiskScore(game, card);
            if (heuristic > bestMove.heuristic) {
                bestMove = BotMove{handIndex, -1, heuristic};
            }
            continue;
        }

        for (std::size_t optionIndex = 0; optionIndex < options.size(); ++optionIndex) {
            const CaptureOption& option = options[optionIndex];
            float heuristic = 0.0f;
            const bool clearsTable = option.tableIndices.size() == game.tableCards.size();
            if (clearsTable && !finalPlay) {
                heuristic += 100000.0f;
            }
            if (option.takesSettebello) {
                heuristic += 50000.0f;
            }
            heuristic += static_cast<float>(option.denariCount) * 2800.0f;
            heuristic += static_cast<float>(option.capturedCount) * 340.0f;
            heuristic += static_cast<float>(option.primieraGain) * 9.0f;
            if (card.suit == Suit::Denari) {
                heuristic += 140.0f;
            }
            if (card.rank == 7) {
                heuristic += 100.0f;
            }

            if (heuristic > bestMove.heuristic) {
                bestMove = BotMove{handIndex, static_cast<int>(optionIndex), heuristic};
            }
        }
    }

    return bestMove;
}

float smoothStep(float t) {
    t = std::clamp(t, 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

float flipScale(float localT) {
    localT = std::clamp(localT, 0.0f, 1.0f);
    if (localT < 0.5f) {
        return 1.0f - localT * 2.0f;
    }
    return (localT - 0.5f) * 2.0f;
}

SDL_FRect lerpRect(const SDL_FRect& a, const SDL_FRect& b, float t) {
    const float k = smoothStep(t);
    return SDL_FRect{
        a.x + (b.x - a.x) * k,
        a.y + (b.y - a.y) * k,
        a.w + (b.w - a.w) * k,
        a.h + (b.h - a.h) * k,
    };
}

SDL_FRect stockSourceRect() {
    return SDL_FRect{kBaseWidth * 0.5f - kCardW * 0.5f, kTableZoneY + 66.0f, kCardW, kCardH};
}

SDL_FRect avatarRectForPlayer(int player) {
    return (player == 0)
        ? SDL_FRect{18.0f, 686.0f, 50.0f, 50.0f}
        : SDL_FRect{18.0f, 84.0f, 50.0f, 50.0f};
}

SDL_FRect capturePileRectForPlayer(int player) {
    const SDL_FRect avatarRect = avatarRectForPlayer(player);
    return SDL_FRect{avatarRect.x + avatarRect.w * 0.5f - 18.0f, avatarRect.y + avatarRect.h * 0.5f - 24.0f, 36.0f, 52.0f};
}

SDL_FRect captureFocusRect() {
    return SDL_FRect{kBaseWidth * 0.5f - kCardW * 0.5f, 446.0f, kCardW, kCardH};
}

SDL_FRect captureCompareBoxRect() {
    return SDL_FRect{kBaseWidth * 0.5f - 128.0f, kBaseHeight * 0.5f - 46.0f, 256.0f, 68.0f};
}

SDL_FRect captureLineupRect(int slot, int total) {
    const SDL_FRect box = captureCompareBoxRect();
    const float lineCardW = 42.0f;
    const float lineCardH = 62.0f;
    const float gap = 8.0f;
    const float totalW = static_cast<float>(total) * lineCardW + static_cast<float>(std::max(0, total - 1)) * gap;
    const float startX = box.x + (box.w - totalW) * 0.5f;
    return SDL_FRect{startX + static_cast<float>(slot) * (lineCardW + gap), box.y + (box.h - lineCardH) * 0.5f, lineCardW, lineCardH};
}

SDL_FPoint rectCenter(const SDL_FRect& rect) {
    return SDL_FPoint{rect.x + rect.w * 0.5f, rect.y + rect.h * 0.5f};
}

void drawCaptureRays(App& app) {
    for (const CaptureRay& ray : app.captureRays) {
        if (ray.elapsed < ray.delay || ray.elapsed > ray.delay + ray.duration) {
            continue;
        }

        const float t = std::clamp((ray.elapsed - ray.delay) / ray.duration, 0.0f, 1.0f);
        const float alpha = 1.0f - t;
        const SDL_FPoint from = ray.from;
        const SDL_FPoint to = ray.to;
        const float dx = to.x - from.x;
        const float dy = to.y - from.y;
        const float nx = -dy;
        const float ny = dx;
        const float length = std::max(1.0f, std::sqrt(dx * dx + dy * dy));
        const float jitterScale = (1.0f - t) * 9.0f;

        setColor(app.renderer, 255, 246, 190, static_cast<std::uint8_t>(210.0f * alpha));
        SDL_FPoint previous = from;
        constexpr int segments = 5;
        for (int i = 1; i <= segments; ++i) {
            const float segT = static_cast<float>(i) / static_cast<float>(segments);
            SDL_FPoint point{from.x + dx * segT, from.y + dy * segT};
            if (i != segments) {
                const float swing = ((i % 2 == 0) ? -1.0f : 1.0f) * jitterScale;
                point.x += (nx / length) * swing;
                point.y += (ny / length) * swing;
            }
            SDL_RenderLine(app.renderer, previous.x, previous.y, point.x, point.y);
            SDL_RenderLine(app.renderer, previous.x, previous.y + 1.0f, point.x, point.y + 1.0f);
            previous = point;
        }

        fillCircle(app.renderer, to.x, to.y, 5.0f + 4.0f * alpha, 255, 228, 132, static_cast<std::uint8_t>(120.0f * alpha));
    }
}

void drawTextureCircleMasked(SDL_Renderer* renderer, SDL_Texture* texture, const SDL_FRect& rect) {
    if (!texture) {
        return;
    }

    float texW = 0.0f;
    float texH = 0.0f;
    if (!SDL_GetTextureSize(texture, &texW, &texH)) {
        SDL_RenderTexture(renderer, texture, nullptr, &rect);
        return;
    }

    const float radius = std::min(rect.w, rect.h) * 0.5f;
    const float cx = rect.x + rect.w * 0.5f;
    const float cy = rect.y + rect.h * 0.5f;
    const int rows = static_cast<int>(rect.h);

    for (int row = 0; row < rows; ++row) {
        const float y = rect.y + static_cast<float>(row) + 0.5f;
        const float dy = y - cy;
        const float halfW = std::sqrt(std::max(0.0f, radius * radius - dy * dy));
        const float x0 = std::max(rect.x, cx - halfW);
        const float x1 = std::min(rect.x + rect.w, cx + halfW);
        if (x1 <= x0) {
            continue;
        }
        const SDL_FRect src{
            (x0 - rect.x) / rect.w * texW,
            static_cast<float>(row) / rect.h * texH,
            (x1 - x0) / rect.w * texW,
            texH / rect.h,
        };
        const SDL_FRect dst{x0, rect.y + static_cast<float>(row), x1 - x0, 1.0f};
        SDL_RenderTexture(renderer, texture, &src, &dst);
    }
}

void drawTurnAvatar(App& app, int player, bool active) {
    const SDL_FRect rect = avatarRectForPlayer(player);
    const float cx = rect.x + rect.w * 0.5f;
    const float cy = rect.y + rect.h * 0.5f;
    const float pulse = 0.5f + 0.5f * std::sin(app.time * 2.5f + static_cast<float>(player));
    if (active) {
        fillCircle(app.renderer, cx, cy, rect.w * 0.7f + pulse * 4.0f, 255, 205, 106, 36);
    }
    fillCircle(app.renderer, cx, cy, rect.w * 0.5f, active ? 86 : 40, active ? 62 : 52, active ? 34 : 58, 245);
    SDL_Texture* avatar = loadTexture(app.renderer, avatarTexturePath(player));
    if (avatar) {
        SDL_FRect avatarRect{rect.x + 1.5f, rect.y + 1.5f, rect.w - 3.0f, rect.h - 3.0f};
        drawTextureCircleMasked(app.renderer, avatar, avatarRect);
    } else {
        fillCircle(app.renderer, cx, cy, rect.w * 0.42f, 227, 219, 204, 255);
    }
    strokeCircle(app.renderer, cx, cy, rect.w * 0.54f, active ? 247 : 201, active ? 214 : 180, active ? 130 : 156, active ? 220 : 90);
    if (active) {
        strokeCircle(app.renderer, cx, cy, rect.w * 0.59f + pulse * 1.4f, 255, 230, 170, 92);
    }
}

bool shouldHideStaticTableCard(const App& app, int cardId) {
    return std::any_of(app.playFlights.begin(), app.playFlights.end(), [cardId](const PlayFlight& flight) {
        return flight.hideTableCard && flight.card.id == cardId && flight.elapsed < flight.duration;
    });
}

std::vector<SDL_FRect> handLayout(std::size_t count, float y, float cardW, float cardH, float maxWidth);
std::vector<SDL_FRect> tableLayout(std::size_t count);

void startDealSequence(App& app, bool includeTable, bool playShuffleSound) {
    app.dealFlights.clear();
    app.visibleHandCounts = {0, 0};
    app.visibleTableCount = includeTable ? 0 : static_cast<int>(app.game.tableCards.size());
    app.dealing = true;

    const SDL_FRect stockRect = stockSourceRect();
    const auto playerRects = handLayout(app.game.players[0].hand.size(), kPlayerHandY, kHandCardW, kHandCardH, 430.0f);
    const auto botRects = handLayout(app.game.players[1].hand.size(), kBotHandY, 54.0f, 80.0f, 320.0f);
    const auto tableRects = includeTable ? tableLayout(app.game.tableCards.size()) : std::vector<SDL_FRect>{};

    float delay = 0.0f;
    if (playShuffleSound) {
        playSound(app, SoundEffect::Shuffle);
    }
    playSound(app, SoundEffect::Deal);

    for (std::size_t i = 0; i < app.game.players[0].hand.size(); ++i) {
        app.dealFlights.push_back(DealFlight{app.game.players[0].hand[i], 0, stockRect, playerRects[i], 0.0f, delay, 0.34f, true});
        delay += 0.08f;
        app.dealFlights.push_back(DealFlight{app.game.players[1].hand[i], 1, stockRect, botRects[i], 0.0f, delay, 0.34f, false});
        delay += 0.08f;
    }

    if (includeTable) {
        for (std::size_t i = 0; i < app.game.tableCards.size(); ++i) {
            app.dealFlights.push_back(DealFlight{app.game.tableCards[i], 2, stockRect, tableRects[i], 0.0f, delay, 0.32f, true});
            delay += 0.06f;
        }
    }
}

std::vector<SDL_FRect> handLayout(std::size_t count, float y, float cardW, float cardH, float maxWidth = 392.0f) {
    std::vector<SDL_FRect> rects;
    rects.reserve(count);
    if (count == 0) {
        return rects;
    }

    float spacing = 18.0f;
    if (count > 1) {
        const float idealWidth = static_cast<float>(count) * cardW + static_cast<float>(count - 1) * spacing;
        if (idealWidth > maxWidth) {
            spacing = (maxWidth - static_cast<float>(count) * cardW) / static_cast<float>(count - 1);
        }
    }
    const float totalW = static_cast<float>(count) * cardW + static_cast<float>(count - 1) * spacing;
    const float startX = (kBaseWidth - totalW) * 0.5f;
    for (std::size_t i = 0; i < count; ++i) {
        rects.push_back(SDL_FRect{startX + static_cast<float>(i) * (cardW + spacing), y, cardW, cardH});
    }
    return rects;
}

std::vector<SDL_FRect> tableLayout(std::size_t count) {
    std::vector<SDL_FRect> rects;
    rects.reserve(count);
    if (count == 0) {
        return rects;
    }

    const int columns = (count <= 4) ? static_cast<int>(count) : 4;
    const int rows = static_cast<int>((count + static_cast<std::size_t>(columns) - 1) / static_cast<std::size_t>(columns));
    const float gapX = 14.0f;
    const float gapY = 14.0f;
    const float totalW = columns * kCardW + static_cast<float>(columns - 1) * gapX;
    const float totalH = rows * kCardH + static_cast<float>(rows - 1) * gapY;
    const float startX = (kBaseWidth - totalW) * 0.5f;
    const float startY = kTableZoneY + std::max(0.0f, (kTableZoneH - totalH) * 0.5f);

    for (std::size_t i = 0; i < count; ++i) {
        const int row = static_cast<int>(i) / columns;
        const int col = static_cast<int>(i) % columns;
        rects.push_back(SDL_FRect{
            startX + static_cast<float>(col) * (kCardW + gapX),
            startY + static_cast<float>(row) * (kCardH + gapY),
            kCardW,
            kCardH,
        });
    }
    return rects;
}

std::vector<SDL_FRect> captureOptionLayout(std::size_t count) {
    std::vector<SDL_FRect> rects;
    rects.reserve(count);
    if (count == 0) {
        return rects;
    }
    const float itemW = (count <= 2) ? 172.0f : 132.0f;
    const float itemH = 34.0f;
    const float gap = 10.0f;
    const float totalW = static_cast<float>(count) * itemW + static_cast<float>(count - 1) * gap;
    const float startX = (kBaseWidth - totalW) * 0.5f;
    for (std::size_t i = 0; i < count; ++i) {
        rects.push_back(SDL_FRect{startX + static_cast<float>(i) * (itemW + gap), kCaptureOptionsY, itemW, itemH});
    }
    return rects;
}

void drawButton(SDL_Renderer* renderer, const SDL_FRect& rect, const std::string& label, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    fillRect(renderer, rect, r, g, b, 235);
    strokeRect(renderer, rect, 34, 40, 51, 255);
    setColor(renderer, 24, 24, 24, 255);
    uiText(renderer, rect.x + rect.w * 0.5f - uiTextWidth(label, 1.12f) * 0.5f, rect.y + 8.0f, label, 1.12f);
}

void drawCloseIconButton(SDL_Renderer* renderer, const SDL_FRect& rect) {
    fillRect(renderer, rect, 236, 225, 193);
    strokeRect(renderer, rect, 63, 45, 26);
    setColor(renderer, 120, 43, 28);
    SDL_RenderLine(renderer, rect.x + 8.0f, rect.y + 8.0f, rect.x + rect.w - 8.0f, rect.y + rect.h - 8.0f);
    SDL_RenderLine(renderer, rect.x + rect.w - 8.0f, rect.y + 8.0f, rect.x + 8.0f, rect.y + rect.h - 8.0f);
}

void drawMenuIconButton(SDL_Renderer* renderer, const SDL_FRect& rect) {
    fillRect(renderer, rect, 228, 179, 70);
    strokeRect(renderer, rect, 63, 45, 26);
    setColor(renderer, 39, 31, 23);
    const float x0 = rect.x + 20.0f;
    const float x1 = rect.x + rect.w - 20.0f;
    const float y = rect.y + 12.0f;
    for (int i = 0; i < 3; ++i) {
        const float yy = y + static_cast<float>(i) * 7.0f;
        SDL_RenderLine(renderer, x0, yy, x1, yy);
        SDL_RenderLine(renderer, x0, yy + 1.0f, x1, yy + 1.0f);
    }
}

void drawSoundIconButton(SDL_Renderer* renderer, const SDL_FRect& rect, bool enabled) {
    fillRect(renderer, rect, enabled ? 223 : 170, enabled ? 210 : 170, enabled ? 172 : 170);
    strokeRect(renderer, rect, 63, 45, 26);
    setColor(renderer, 39, 31, 23);
    const SDL_FRect speaker{rect.x + 14.0f, rect.y + 20.0f, 10.0f, 16.0f};
    fillRect(renderer, speaker, 39, 31, 23);
    SDL_RenderLine(renderer, rect.x + 24.0f, rect.y + 22.0f, rect.x + 34.0f, rect.y + 16.0f);
    SDL_RenderLine(renderer, rect.x + 24.0f, rect.y + 34.0f, rect.x + 34.0f, rect.y + 40.0f);
    if (enabled) {
        SDL_RenderLine(renderer, rect.x + 38.0f, rect.y + 20.0f, rect.x + 44.0f, rect.y + 16.0f);
        SDL_RenderLine(renderer, rect.x + 38.0f, rect.y + 36.0f, rect.x + 44.0f, rect.y + 40.0f);
        SDL_RenderLine(renderer, rect.x + 42.0f, rect.y + 24.0f, rect.x + 48.0f, rect.y + 20.0f);
        SDL_RenderLine(renderer, rect.x + 42.0f, rect.y + 32.0f, rect.x + 48.0f, rect.y + 36.0f);
    } else {
        SDL_RenderLine(renderer, rect.x + 36.0f, rect.y + 18.0f, rect.x + 48.0f, rect.y + 40.0f);
        SDL_RenderLine(renderer, rect.x + 48.0f, rect.y + 18.0f, rect.x + 36.0f, rect.y + 40.0f);
    }
}

void drawCenteredButtonLabel(SDL_Renderer* renderer, const SDL_FRect& rect, const std::string& label) {
    setColor(renderer, 48, 38, 28, 255);
    uiText(renderer, rect.x + rect.w * 0.5f - uiTextWidth(label, 0.98f) * 0.5f, rect.y + rect.h + 8.0f, label, 0.98f);
}

void drawMenuOverlay(App& app) {
    fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 0, 0, 0, 130);
    const SDL_FRect panel{82.0f, 232.0f, 316.0f, 240.0f};
    app.menuCloseRect = SDL_FRect{panel.x + panel.w - 38.0f, panel.y + 12.0f, 26.0f, 26.0f};
    fillRect(app.renderer, panel, 242, 234, 207, 248);
    strokeRect(app.renderer, panel, 72, 55, 34);
    setColor(app.renderer, 42, 34, 26);
    uiText(app.renderer, panel.x + 24.0f, panel.y + 20.0f, "Menu", 1.18f);
    drawCloseIconButton(app.renderer, app.menuCloseRect);

    app.menuNewGameRect = SDL_FRect{panel.x + 42.0f, panel.y + 76.0f, panel.w - 84.0f, 44.0f};
    app.soundToggleRect = SDL_FRect{panel.x + 74.0f, panel.y + 146.0f, 60.0f, 60.0f};
    app.menuLobbyRect = SDL_FRect{panel.x + panel.w - 134.0f, panel.y + 146.0f, 60.0f, 60.0f};
    drawButton(app.renderer, app.menuNewGameRect, "New Game", 240, 214, 132);
    drawSoundIconButton(app.renderer, app.soundToggleRect, app.audioEnabled);
    drawButton(app.renderer, app.menuLobbyRect, "Lobby", 175, 219, 182);
    drawCenteredButtonLabel(app.renderer, app.soundToggleRect, app.audioEnabled ? "Sound" : "Muted");
}

void drawCardFallback(SDL_Renderer* renderer, const SDL_FRect& rect, const Card& card) {
    fillRect(renderer, rect, 244, 238, 225, 255);
    strokeRect(renderer, rect, 74, 52, 41, 255);
    setColor(renderer, 44, 44, 44, 255);
    uiText(renderer, rect.x + 8.0f, rect.y + 8.0f, rankLabel(card.rank), 1.0f);
    uiText(renderer, rect.x + 8.0f, rect.y + 24.0f, suitShort(card.suit), 1.0f);
}

void drawCardFace(App& app, const SDL_FRect& rect, const Card& card) {
    if (SDL_Texture* texture = loadTexture(app.renderer, cardTexturePath(card.id))) {
        SDL_RenderTexture(app.renderer, texture, nullptr, &rect);
    } else {
        drawCardFallback(app.renderer, rect, card);
    }
}

void drawCardBack(App& app, const SDL_FRect& rect) {
    if (SDL_Texture* texture = loadTexture(app.renderer, cardBackTexturePath())) {
        SDL_RenderTexture(app.renderer, texture, nullptr, &rect);
        return;
    }
    fillRect(app.renderer, rect, 28, 84, 96, 255);
    strokeRect(app.renderer, rect, 230, 221, 196, 255);
}

void drawCard(App& app, const SDL_FRect& rect, const Card& card, bool faceUp, bool highlight = false, bool selected = false) {
    const SDL_FRect drawRect{
        rect.x,
        rect.y - (selected ? 12.0f : 0.0f),
        rect.w,
        rect.h,
    };
    fillRect(app.renderer, SDL_FRect{drawRect.x + 3.0f, drawRect.y + 4.0f, drawRect.w, drawRect.h}, 0, 0, 0, 42);
    if (faceUp) {
        drawCardFace(app, drawRect, card);
    } else {
        drawCardBack(app, drawRect);
    }
    if (faceUp) {
        const SDL_FRect badge{drawRect.x + drawRect.w - 22.0f, drawRect.y + 6.0f, 16.0f, 16.0f};
        fillRect(app.renderer, badge, 20, 24, 27, 190);
        strokeRect(app.renderer, badge, 244, 226, 176, 220);
        setColor(app.renderer, 255, 246, 222, 255);
        const std::string valueText = std::to_string(card.captureValue);
        uiText(app.renderer, badge.x + badge.w * 0.5f - uiTextWidth(valueText, 0.72f) * 0.5f, badge.y + 4.0f, valueText, 0.72f);
    }
    if (highlight) {
        strokeRect(app.renderer, SDL_FRect{drawRect.x - 2.0f, drawRect.y - 2.0f, drawRect.w + 4.0f, drawRect.h + 4.0f}, 248, 220, 112, 255);
        strokeRect(app.renderer, SDL_FRect{drawRect.x - 4.0f, drawRect.y - 4.0f, drawRect.w + 8.0f, drawRect.h + 8.0f}, 255, 245, 214, 120);
    }
}

void updatePhaseAfterTurn(App& app);
void finalizeRound(App& app);

void startRound(App& app) {
    GameState& game = app.game;
    game.deck = makeDeck();
    shuffleDeck(game.deck, app.rng);
    game.tableCards.clear();
    game.validCaptures.clear();
    game.selectedHandIndex = -1;
    game.highlightedCaptureIndex = 0;
    game.roundOver = false;
    game.matchOver = false;
    game.matchWinner = -1;
    game.lastCapturer = -1;
    game.phase = GamePhase::InitRound;
    game.dealer = (game.roundNumber - 1) % 2;
    game.starter = 1 - game.dealer;
    for (PlayerState& player : game.players) {
        player.hand.clear();
        player.capturedCards.clear();
        player.scopaCount = 0;
    }

    dealNextHands(game);
    pushInitialTable(game);
    game.currentTurn = game.starter;
    game.statusMessage = (game.currentTurn == 0) ? "Your turn" : "Opp is thinking";
    app.botDelay = (game.currentTurn == 1) ? 0.65f : -1.0f;
    game.phase = (game.currentTurn == 0) ? GamePhase::PlayerTurn : GamePhase::BotTurn;
    startDealSequence(app, true, true);
}

void resetMatch(App& app) {
    app.game.roundNumber = 1;
    app.game.players[0].matchScore = 0;
    app.game.players[1].matchScore = 0;
    startRound(app);
}

void beginNextRound(App& app) {
    ++app.game.roundNumber;
    startRound(app);
}

RoundScoreBreakdown scoreRound(GameState& game) {
    RoundScoreBreakdown result;
    const int capturedCount0 = static_cast<int>(game.players[0].capturedCards.size());
    const int capturedCount1 = static_cast<int>(game.players[1].capturedCards.size());
    if (capturedCount0 > capturedCount1) {
        result.carte[0] = 1;
    } else if (capturedCount1 > capturedCount0) {
        result.carte[1] = 1;
    }

    const int denari0 = countSuit(game.players[0].capturedCards, Suit::Denari);
    const int denari1 = countSuit(game.players[1].capturedCards, Suit::Denari);
    if (denari0 > denari1) {
        result.denari[0] = 1;
    } else if (denari1 > denari0) {
        result.denari[1] = 1;
    }

    result.settebello[0] = hasCard(game.players[0].capturedCards, Suit::Denari, 7) ? 1 : 0;
    result.settebello[1] = hasCard(game.players[1].capturedCards, Suit::Denari, 7) ? 1 : 0;

    bool primieraEligible0 = false;
    bool primieraEligible1 = false;
    result.primieraScore[0] = primieraScore(game.players[0].capturedCards, primieraEligible0);
    result.primieraScore[1] = primieraScore(game.players[1].capturedCards, primieraEligible1);
    if (primieraEligible0 || primieraEligible1) {
        if (primieraEligible0 && (!primieraEligible1 || result.primieraScore[0] > result.primieraScore[1])) {
            result.primiera[0] = 1;
        } else if (primieraEligible1 && (!primieraEligible0 || result.primieraScore[1] > result.primieraScore[0])) {
            result.primiera[1] = 1;
        }
    }

    result.scope[0] = game.players[0].scopaCount;
    result.scope[1] = game.players[1].scopaCount;

    for (int player = 0; player < 2; ++player) {
        result.total[player] = result.carte[player] + result.denari[player] + result.settebello[player] +
                               result.primiera[player] + result.scope[player];
        game.players[player].matchScore += result.total[player];
    }

    return result;
}

void finalizeRound(App& app) {
    GameState& game = app.game;
    if (!game.tableCards.empty() && game.lastCapturer >= 0) {
        auto& captured = game.players[game.lastCapturer].capturedCards;
        captured.insert(captured.end(), game.tableCards.begin(), game.tableCards.end());
        game.tableCards.clear();
    }

    game.lastRoundScore = scoreRound(game);
    game.roundOver = true;
    if (game.lastRoundScore.total[0] > game.lastRoundScore.total[1]) {
        showBanner(app,
                   "Round +" + std::to_string(game.lastRoundScore.total[0]),
                   "You win this round", 1.6f);
    } else if (game.lastRoundScore.total[1] > game.lastRoundScore.total[0]) {
        showBanner(app,
                   "Opp +" + std::to_string(game.lastRoundScore.total[1]),
                   "Opp wins this round", 1.6f);
    } else {
        showBanner(app,
                   "Round tied",
                   "You +" + std::to_string(game.lastRoundScore.total[0]) + "  Opp +" + std::to_string(game.lastRoundScore.total[1]), 1.6f);
    }
    const bool playerReached = game.players[0].matchScore >= kMatchTargetScore;
    const bool botReached = game.players[1].matchScore >= kMatchTargetScore;
    if (playerReached || botReached) {
        if (game.players[0].matchScore != game.players[1].matchScore) {
            game.matchOver = true;
            game.matchWinner = (game.players[0].matchScore > game.players[1].matchScore) ? 0 : 1;
            game.phase = GamePhase::MatchOver;
            game.statusMessage = (game.matchWinner == 0) ? "You win the match" : "Bot wins the match";
            return;
        }
    }
    game.phase = GamePhase::RoundSummary;
    game.statusMessage = "Round complete";
}

void updatePhaseAfterTurn(App& app) {
    GameState& game = app.game;
    game.validCaptures.clear();
    game.selectedHandIndex = -1;
    game.highlightedCaptureIndex = 0;

    if (game.players[0].hand.empty() && game.players[1].hand.empty()) {
        if (!game.deck.empty()) {
            app.pendingHandDeal = true;
            app.pendingHandDealTimer = 2.0f;
            app.pauseForEffectTimer = std::max(app.pauseForEffectTimer, 0.95f);
            game.phase = GamePhase::InitRound;
            game.statusMessage = "Hand complete";
            showBanner(app, "Next hand", "Dealing 3 cards each", 2.0f);
            return;
        } else {
            finalizeRound(app);
            return;
        }
    }

    game.phase = (game.currentTurn == 0) ? GamePhase::PlayerTurn : GamePhase::BotTurn;
    game.statusMessage = (game.currentTurn == 0) ? "Your turn" : "Opp is thinking";
    app.botDelay = (game.currentTurn == 1) ? 0.65f : -1.0f;
    if (game.currentTurn == 0 && !app.dealing) {
        notifyMyTurn(app);
    }
}

void applyMove(App& app, int playerIndex, std::size_t handIndex, int captureIndex) {
    GameState& game = app.game;
    PlayerState& player = game.players[playerIndex];
    if (handIndex >= player.hand.size()) {
        return;
    }

    const bool finalPlay = isFinalPlayOfRound(game);
    const auto sourceRects = (playerIndex == 0)
        ? handLayout(player.hand.size(), kPlayerHandY, kHandCardW, kHandCardH, 430.0f)
        : handLayout(player.hand.size(), kBotHandY, 54.0f, 80.0f, 320.0f);
    const SDL_FRect sourceRect = handIndex < sourceRects.size()
        ? sourceRects[handIndex]
        : avatarRectForPlayer(playerIndex);
    const auto tableRectsBeforeMove = tableLayout(game.tableCards.size());
    const Card playedCard = player.hand[handIndex];
    player.hand.erase(player.hand.begin() + static_cast<std::ptrdiff_t>(handIndex));
    playSound(app, SoundEffect::Play);

    if (captureIndex >= 0 && captureIndex < static_cast<int>(game.validCaptures.size())) {
        const CaptureOption option = game.validCaptures[static_cast<std::size_t>(captureIndex)];
        auto& captured = player.capturedCards;
        captured.push_back(playedCard);

        const SDL_FRect focusRect = captureFocusRect();
        const SDL_FRect pileRect = capturePileRectForPlayer(playerIndex);
        constexpr float kFocusDuration = 0.28f;
        constexpr float kRayDelay = 0.32f;
        constexpr float kRayDuration = 0.42f;
        constexpr float kGatherStart = 0.82f;
        constexpr float kGatherDuration = 0.28f;
        constexpr float kFlyHomeDelay = 1.26f;
        constexpr float kFlyHomeDuration = 0.38f;
        const SDL_FPoint focusCenter = rectCenter(focusRect);
        app.playFlights.push_back(PlayFlight{playedCard, sourceRect, focusRect, 0.0f, 0.0f, kFocusDuration, 1.0f, 1.0f, false});
        app.playFlights.push_back(PlayFlight{playedCard, focusRect, focusRect, 0.0f, kFocusDuration, kFlyHomeDelay - kFocusDuration, 1.0f, 1.06f, false});
        app.playFlights.push_back(PlayFlight{playedCard, focusRect, pileRect, 0.0f, kFlyHomeDelay, kFlyHomeDuration, 1.06f, 1.0f, false});

        std::vector<int> sortedIndices = option.tableIndices;
        std::sort(sortedIndices.begin(), sortedIndices.end(), std::greater<int>());
        float gatherDelay = kGatherStart;
        for (int index : sortedIndices) {
            const Card capturedCard = game.tableCards[static_cast<std::size_t>(index)];
            const SDL_FRect fromRect = tableRectsBeforeMove[static_cast<std::size_t>(index)];
            const SDL_FPoint targetCenter = rectCenter(fromRect);
            captured.push_back(game.tableCards[static_cast<std::size_t>(index)]);
            game.tableCards.erase(game.tableCards.begin() + static_cast<std::ptrdiff_t>(index));
            app.captureRays.push_back(CaptureRay{focusCenter, targetCenter, 0.0f, kRayDelay, kRayDuration});
            app.playFlights.push_back(PlayFlight{capturedCard, fromRect, fromRect, 0.0f, 0.0f, kGatherStart, 1.0f, 1.0f, false});
            app.playFlights.push_back(PlayFlight{capturedCard, fromRect, focusRect, 0.0f, gatherDelay, kGatherDuration, 1.0f, 1.14f, false});
            app.playFlights.push_back(PlayFlight{capturedCard, focusRect, pileRect, 0.0f, kFlyHomeDelay + 0.05f, kFlyHomeDuration, 1.14f, 1.0f, false});
            gatherDelay += 0.08f;
        }

        game.lastCapturer = playerIndex;
        app.pauseForEffectTimer = std::max(app.pauseForEffectTimer, kFlyHomeDelay + kFlyHomeDuration + 0.22f);
        if (game.tableCards.empty() && !finalPlay) {
            ++player.scopaCount;
            game.statusMessage = (playerIndex == 0) ? "Scopa!" : "Opp scored Scopa";
            app.pauseForEffectTimer = std::max(app.pauseForEffectTimer, 1.35f);
            showBanner(app,
                       (playerIndex == 0) ? "Scopa!" : "Opp Scopa!",
                       "Table cleared", 1.35f);
            spawnFireworkBurst(app, kBaseWidth * 0.5f, kBaseHeight * 0.42f);
            spawnFireworkBurst(app, kBaseWidth * 0.34f, kBaseHeight * 0.36f);
            spawnFireworkBurst(app, kBaseWidth * 0.66f, kBaseHeight * 0.36f);
            playSound(app, SoundEffect::CompareWin);
        }
    } else {
        game.tableCards.push_back(playedCard);
        const SDL_FRect targetRect = tableLayout(game.tableCards.size()).back();
        app.playFlights.push_back(PlayFlight{playedCard, sourceRect, targetRect, 0.0f, 0.0f, 0.26f, 1.0f, 1.0f, true});
        game.statusMessage = (playerIndex == 0) ? "Card placed on table" : "Bot placed a card";
    }

    sortHand(game.players[0].hand);
    sortHand(game.players[1].hand);
    game.currentTurn = 1 - playerIndex;
    updatePhaseAfterTurn(app);
}

void choosePlayerCard(App& app, int handIndex) {
    GameState& game = app.game;
    if (handIndex < 0 || handIndex >= static_cast<int>(game.players[0].hand.size())) {
        return;
    }
    const Card& card = game.players[0].hand[static_cast<std::size_t>(handIndex)];
    const auto options = getCaptureOptions(card, game.tableCards);

    if (options.empty()) {
        game.validCaptures.clear();
        applyMove(app, 0, static_cast<std::size_t>(handIndex), -1);
        return;
    }

    if (options.size() == 1) {
        game.validCaptures = options;
        applyMove(app, 0, static_cast<std::size_t>(handIndex), 0);
        return;
    }

    game.selectedHandIndex = handIndex;
    game.validCaptures = options;
    game.highlightedCaptureIndex = 0;
    game.phase = GamePhase::PlayerChooseCapture;
    game.statusMessage = "Choose a capture";
}

void updateBotTurn(App& app, float delta) {
    GameState& game = app.game;
    if (game.phase != GamePhase::BotTurn || app.dealing || !app.playFlights.empty() || app.pauseForEffectTimer > 0.0f || app.pendingHandDeal) {
        return;
    }
    app.botDelay -= delta;
    if (app.botDelay > 0.0f) {
        return;
    }

    BotMove move = chooseBotMove(game);
    const Card& chosenCard = game.players[1].hand[move.handIndex];
    game.validCaptures = getCaptureOptions(chosenCard, game.tableCards);
    applyMove(app, 1, move.handIndex, move.captureIndex);
}

void updateApp(App& app, float delta) {
    app.time += delta;
    cleanupFinishedAudioStreams(app);
    app.bannerTimer = std::max(0.0f, app.bannerTimer - delta);
    app.pauseForEffectTimer = std::max(0.0f, app.pauseForEffectTimer - delta);
    app.menuElapsed = app.menuOpen ? (app.menuElapsed + delta) : 0.0f;

    for (std::size_t i = 0; i < app.fireworkParticles.size();) {
        FireworkParticle& particle = app.fireworkParticles[i];
        particle.elapsed += delta;
        if (particle.elapsed >= particle.duration) {
            app.fireworkParticles.erase(app.fireworkParticles.begin() + static_cast<std::ptrdiff_t>(i));
            continue;
        }
        ++i;
    }

    for (std::size_t i = 0; i < app.captureRays.size();) {
        CaptureRay& ray = app.captureRays[i];
        ray.elapsed += delta;
        if (ray.elapsed >= ray.delay + ray.duration) {
            app.captureRays.erase(app.captureRays.begin() + static_cast<std::ptrdiff_t>(i));
            continue;
        }
        ++i;
    }

    if (app.pendingHandDeal) {
        app.pendingHandDealTimer = std::max(0.0f, app.pendingHandDealTimer - delta);
        if (app.pendingHandDealTimer <= 0.0f) {
            dealNextHands(app.game);
            app.game.currentTurn = app.game.starter;
            app.pendingHandDeal = false;
            app.game.phase = (app.game.currentTurn == 0) ? GamePhase::PlayerTurn : GamePhase::BotTurn;
            app.game.statusMessage = (app.game.currentTurn == 0) ? "Your turn" : "Opp is thinking";
            app.botDelay = (app.game.currentTurn == 1) ? 0.65f : -1.0f;
            startDealSequence(app, false, false);
        }
    }

    for (std::size_t i = 0; i < app.dealFlights.size();) {
        DealFlight& flight = app.dealFlights[i];
        flight.elapsed += delta;
        if (flight.elapsed < flight.delay) {
            ++i;
            continue;
        }

        const float localT = (flight.elapsed - flight.delay) / flight.duration;
        if (localT >= 1.0f) {
            if (flight.lane == 0 || flight.lane == 1) {
                ++app.visibleHandCounts[static_cast<std::size_t>(flight.lane)];
            } else {
                ++app.visibleTableCount;
            }
            playSound(app, flight.faceUp ? SoundEffect::Draw : SoundEffect::Deal);
            app.dealFlights.erase(app.dealFlights.begin() + static_cast<std::ptrdiff_t>(i));
            continue;
        }
        ++i;
    }

    if (app.dealing && app.dealFlights.empty()) {
        app.dealing = false;
        app.visibleHandCounts[0] = static_cast<int>(app.game.players[0].hand.size());
        app.visibleHandCounts[1] = static_cast<int>(app.game.players[1].hand.size());
        app.visibleTableCount = static_cast<int>(app.game.tableCards.size());
        if (app.game.phase == GamePhase::PlayerTurn) {
            notifyMyTurn(app);
        }
    }

    for (std::size_t i = 0; i < app.playFlights.size();) {
        PlayFlight& flight = app.playFlights[i];
        flight.elapsed += delta;
        if (flight.elapsed < flight.delay) {
            ++i;
            continue;
        }
        if (flight.elapsed >= flight.delay + flight.duration) {
            app.playFlights.erase(app.playFlights.begin() + static_cast<std::ptrdiff_t>(i));
            continue;
        }
        ++i;
    }

    updateBotTurn(app, delta);
}

void drawTableBackground(App& app) {
    fillRect(app.renderer, SDL_FRect{0.0f, 0.0f, static_cast<float>(kBaseWidth), static_cast<float>(kBaseHeight)}, 15, 64, 47, 255);
    fillRect(app.renderer, SDL_FRect{0.0f, 0.0f, static_cast<float>(kBaseWidth), 118.0f}, 10, 42, 31, 255);
    fillRect(app.renderer, SDL_FRect{0.0f, kBaseHeight - 184.0f, static_cast<float>(kBaseWidth), 184.0f}, 12, 51, 37, 255);
    for (int i = 0; i < 18; ++i) {
        const float x = static_cast<float>(i) * 32.0f;
        setColor(app.renderer, 255, 255, 255, 10);
        SDL_RenderLine(app.renderer, x, 0.0f, x - 90.0f, static_cast<float>(kBaseHeight));
    }
    fillRect(app.renderer, SDL_FRect{20.0f, 154.0f, kBaseWidth - 40.0f, 326.0f}, 6, 28, 20, 78);
    strokeRect(app.renderer, SDL_FRect{20.0f, 154.0f, kBaseWidth - 40.0f, 326.0f}, 236, 218, 172, 70);
}

void drawTopBar(App& app) {
    app.menuRect = SDL_FRect{kBaseWidth - 72.0f, 18.0f, 54.0f, 36.0f};
    drawMenuIconButton(app.renderer, app.menuRect);
    app.lobbyRect = SDL_FRect{};
    app.newMatchRect = SDL_FRect{};

    setColor(app.renderer, 248, 239, 214, 255);
        uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth("Scopa", 1.4f) * 0.5f, 14.0f, "Scopa", 1.4f);
        uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(std::string{"Round "} + std::to_string(app.game.roundNumber), 1.08f) * 0.5f, 44.0f,
            std::string{"Round "} + std::to_string(app.game.roundNumber), 1.08f);

    const std::string scoreLabel = "Match " + std::to_string(app.game.players[0].matchScore) + " - " + std::to_string(app.game.players[1].matchScore);
        uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(scoreLabel, 1.1f) * 0.5f, 66.0f, scoreLabel, 1.1f);
}

void drawCapturedSummary(App& app) {
    const SDL_FRect oppBox{112.0f, 176.0f, 256.0f, 26.0f};
    const SDL_FRect youBox{112.0f, 636.0f, 256.0f, 26.0f};
    fillRect(app.renderer, oppBox, 8, 28, 20, 116);
    fillRect(app.renderer, youBox, 8, 28, 20, 116);
    strokeRect(app.renderer, oppBox, 235, 218, 172, 64);
    strokeRect(app.renderer, youBox, 235, 218, 172, 64);

    setColor(app.renderer, 243, 236, 216, 255);
    const std::string oppSummary = "Opp  cards " + std::to_string(app.game.players[1].capturedCards.size()) +
                                   "  denari " + std::to_string(countSuit(app.game.players[1].capturedCards, Suit::Denari)) +
                                   "  scope " + std::to_string(app.game.players[1].scopaCount);
    const std::string playerSummary = "You  cards " + std::to_string(app.game.players[0].capturedCards.size()) +
                                      "  denari " + std::to_string(countSuit(app.game.players[0].capturedCards, Suit::Denari)) +
                                      "  scope " + std::to_string(app.game.players[0].scopaCount);
    uiText(app.renderer, oppBox.x + oppBox.w * 0.5f - uiTextWidth(oppSummary, 1.0f) * 0.5f, oppBox.y + 4.0f, oppSummary, 1.0f);
    uiText(app.renderer, youBox.x + youBox.w * 0.5f - uiTextWidth(playerSummary, 1.0f) * 0.5f, youBox.y + 4.0f, playerSummary, 1.0f);
}

void drawCaptureCompareZone(App& app) {
    (void)app;
}

void drawHandsAndTable(App& app) {
    app.playerHandRects = handLayout(app.game.players[0].hand.size(), kPlayerHandY, kHandCardW, kHandCardH, 430.0f);
    const auto botHandRects = handLayout(app.game.players[1].hand.size(), kBotHandY, 54.0f, 80.0f, 320.0f);
    app.tableRects = tableLayout(app.game.tableCards.size());

    const std::size_t botVisibleCount = app.dealing ? static_cast<std::size_t>(std::clamp(app.visibleHandCounts[1], 0, static_cast<int>(botHandRects.size()))) : botHandRects.size();
    for (std::size_t i = 0; i < botVisibleCount; ++i) {
        drawCardBack(app, botHandRects[i]);
    }

    std::vector<bool> tableHighlights(app.game.tableCards.size(), false);
    if (!app.game.validCaptures.empty() && app.game.highlightedCaptureIndex >= 0 &&
        app.game.highlightedCaptureIndex < static_cast<int>(app.game.validCaptures.size())) {
        for (int index : app.game.validCaptures[static_cast<std::size_t>(app.game.highlightedCaptureIndex)].tableIndices) {
            if (index >= 0 && index < static_cast<int>(tableHighlights.size())) {
                tableHighlights[static_cast<std::size_t>(index)] = true;
            }
        }
    }

    const std::size_t tableVisibleCount = app.dealing ? static_cast<std::size_t>(std::clamp(app.visibleTableCount, 0, static_cast<int>(app.game.tableCards.size()))) : app.game.tableCards.size();
    for (std::size_t i = 0; i < tableVisibleCount; ++i) {
        if (shouldHideStaticTableCard(app, app.game.tableCards[i].id)) {
            continue;
        }
        drawCard(app, app.tableRects[i], app.game.tableCards[i], true, tableHighlights[i]);
    }

    const std::size_t playerVisibleCount = app.dealing ? static_cast<std::size_t>(std::clamp(app.visibleHandCounts[0], 0, static_cast<int>(app.game.players[0].hand.size()))) : app.game.players[0].hand.size();
    for (std::size_t i = 0; i < playerVisibleCount; ++i) {
        const bool selected = static_cast<int>(i) == app.game.selectedHandIndex;
        drawCard(app, app.playerHandRects[i], app.game.players[0].hand[i], true, false, selected);
    }
}

void drawCaptureOptions(App& app) {
    app.captureOptionRects.clear();
    if (app.game.phase != GamePhase::PlayerChooseCapture || app.game.validCaptures.empty()) {
        return;
    }

    app.captureOptionRects = captureOptionLayout(app.game.validCaptures.size());
    for (std::size_t i = 0; i < app.game.validCaptures.size(); ++i) {
        const bool active = static_cast<int>(i) == app.game.highlightedCaptureIndex;
        drawButton(app.renderer, app.captureOptionRects[i], app.game.validCaptures[i].label, active ? 250 : 224, active ? 214 : 197, active ? 121 : 148);
    }
}

void drawStatus(App& app) {
    fillRect(app.renderer, SDL_FRect{44.0f, kStatusY, 392.0f, 28.0f}, 8, 28, 20, 128);
    setColor(app.renderer, 249, 241, 218, 255);
    uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(app.game.statusMessage, 1.08f) * 0.5f, kStatusY + 5.0f, app.game.statusMessage, 1.08f);
}

void drawBanner(App& app) {
    if (app.bannerTimer <= 0.0f || app.bannerTitle.empty()) {
        return;
    }

    const float alphaT = std::min(1.0f, app.bannerTimer / 0.24f);
    const float rise = smoothStep(std::min(1.0f, app.bannerTimer / 0.36f));
    const bool isScopaBanner = app.bannerTitle.find("Scopa") != std::string::npos;
    const float scale = isScopaBanner ? (1.04f + std::sin(app.time * 10.0f) * 0.05f) : 1.0f;
    const float panelW = isScopaBanner ? 376.0f : 324.0f;
    const float panelH = isScopaBanner ? 128.0f : 90.0f;
    const float panelY = (isScopaBanner ? 314.0f : 344.0f) - (1.0f - rise) * 14.0f;
    SDL_FRect panel{(kBaseWidth - panelW) * 0.5f, panelY, panelW, panelH};
    panel.x += panel.w * (1.0f - scale) * 0.5f;
    panel.y += panel.h * (1.0f - scale) * 0.5f;
    panel.w *= scale;
    panel.h *= scale;
    fillRect(app.renderer, panel, 8, 19, 14, static_cast<std::uint8_t>(152 * alphaT));
    fillRect(app.renderer, SDL_FRect{panel.x + 8.0f, panel.y + 8.0f, panel.w - 16.0f, panel.h - 16.0f}, 255, 255, 255, static_cast<std::uint8_t>(22 * alphaT));
    strokeRect(app.renderer, panel, isScopaBanner ? 255 : 245, isScopaBanner ? 205 : 223, isScopaBanner ? 106 : 166, static_cast<std::uint8_t>(190 * alphaT));
    setColor(app.renderer, 255, 244, 214, static_cast<std::uint8_t>(255 * alphaT));
    uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(app.bannerTitle, isScopaBanner ? 1.88f : 1.28f) * 0.5f, panel.y + (isScopaBanner ? 16.0f : 18.0f), app.bannerTitle, isScopaBanner ? 1.88f : 1.28f);
    if (!app.bannerSubtitle.empty()) {
        uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(app.bannerSubtitle, isScopaBanner ? 1.08f : 0.94f) * 0.5f,
               panel.y + (isScopaBanner ? 78.0f : 52.0f), app.bannerSubtitle, isScopaBanner ? 1.08f : 0.94f);
    }
}

void drawRoundOverlay(App& app, bool matchOver) {
    fillRect(app.renderer, SDL_FRect{20.0f, 176.0f, 440.0f, 502.0f}, 8, 19, 14, 176);
    fillRect(app.renderer, SDL_FRect{28.0f, 184.0f, 424.0f, 486.0f}, 255, 255, 255, 18);
    strokeRect(app.renderer, SDL_FRect{28.0f, 184.0f, 424.0f, 486.0f}, 239, 221, 176, 190);

    setColor(app.renderer, 255, 244, 214, 255);
    const std::string title = matchOver ? ((app.game.matchWinner == 0) ? "You Win Match" : "Bot Wins Match") : "Round Results";
    uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(title, 1.34f) * 0.5f, 212.0f, title, 1.34f);

    const std::array<std::string, 5> labels{"Carte", "Denari", "Settebello", "Primiera", "Scope"};
    const std::array<std::array<int, 2>, 5> values{{
        app.game.lastRoundScore.carte,
        app.game.lastRoundScore.denari,
        app.game.lastRoundScore.settebello,
        app.game.lastRoundScore.primiera,
        app.game.lastRoundScore.scope,
    }};
    for (std::size_t i = 0; i < labels.size(); ++i) {
        const float y = 274.0f + static_cast<float>(i) * 40.0f;
        uiText(app.renderer, 70.0f, y, labels[i], 1.08f);
        uiText(app.renderer, 244.0f, y, std::to_string(values[i][0]), 1.08f);
        uiText(app.renderer, 336.0f, y, std::to_string(values[i][1]), 1.08f);
    }

    const std::string primieraDetail = "Primiera score " + std::to_string(app.game.lastRoundScore.primieraScore[0]) +
                                       " - " + std::to_string(app.game.lastRoundScore.primieraScore[1]);
    uiText(app.renderer, 70.0f, 490.0f, primieraDetail, 1.0f);
    const std::string totalRound = "Round total " + std::to_string(app.game.lastRoundScore.total[0]) +
                                   " - " + std::to_string(app.game.lastRoundScore.total[1]);
    const std::string totalMatch = "Match total " + std::to_string(app.game.players[0].matchScore) +
                                   " - " + std::to_string(app.game.players[1].matchScore);
    uiText(app.renderer, 70.0f, 528.0f, totalRound, 1.08f);
    uiText(app.renderer, 70.0f, 556.0f, totalMatch, 1.08f);

    app.continueRect = SDL_FRect{76.0f, 602.0f, 150.0f, 40.0f};
    app.overlayLobbyRect = SDL_FRect{254.0f, 602.0f, 150.0f, 40.0f};
    drawButton(app.renderer, app.continueRect, matchOver ? "New Match" : "Next Round", 240, 214, 132);
    drawButton(app.renderer, app.overlayLobbyRect, "Lobby", 175, 219, 182);
}

void drawApp(App& app) {
    SDL_SetRenderLogicalPresentation(app.renderer, kBaseWidth, kBaseHeight, SDL_LOGICAL_PRESENTATION_LETTERBOX);
    drawTableBackground(app);
    drawTopBar(app);
    drawTurnAvatar(app, 1, app.game.currentTurn == 1 && !app.dealing);
    drawTurnAvatar(app, 0, app.game.currentTurn == 0 && !app.dealing);
    drawCapturedSummary(app);
    drawHandsAndTable(app);
    drawCaptureOptions(app);
    drawStatus(app);
    drawFireworks(app);

    for (const DealFlight& flight : app.dealFlights) {
        if (flight.elapsed < flight.delay) {
            continue;
        }
        const float t = std::clamp((flight.elapsed - flight.delay) / flight.duration, 0.0f, 1.0f);
        SDL_FRect rect = lerpRect(flight.from, flight.to, t);
        if (flight.faceUp) {
            const float localFlip = flipScale(t);
            rect.x += rect.w * (1.0f - std::max(0.06f, localFlip)) * 0.5f;
            rect.w *= std::max(0.06f, localFlip);
            if (t < 0.5f) {
                drawCardBack(app, rect);
            } else {
                drawCardFace(app, rect, flight.card);
            }
        } else {
            drawCardBack(app, rect);
        }
    }

    drawCaptureCompareZone(app);
    drawCaptureRays(app);

    for (const PlayFlight& flight : app.playFlights) {
        if (flight.elapsed < flight.delay) {
            continue;
        }
        const float t = std::clamp((flight.elapsed - flight.delay) / flight.duration, 0.0f, 1.0f);
        SDL_FRect rect = lerpRect(flight.from, flight.to, t);
        const float scale = std::lerp(flight.scaleFrom, flight.scaleTo, smoothStep(t));
        rect.x += rect.w * (1.0f - scale) * 0.5f;
        rect.y += rect.h * (1.0f - scale) * 0.5f;
        rect.w *= scale;
        rect.h *= scale;
        drawCard(app, rect, flight.card, true);
    }

    drawBanner(app);

    if (app.game.phase == GamePhase::RoundSummary) {
        drawRoundOverlay(app, false);
    } else if (app.game.phase == GamePhase::MatchOver) {
        drawRoundOverlay(app, true);
    }

    if (app.menuOpen) {
        drawMenuOverlay(app);
    }

    SDL_RenderPresent(app.renderer);
}

void handleOverlayTap(App& app, float x, float y) {
    if (pointInRect(x, y, app.overlayLobbyRect)) {
        app.exitAction = ScopaExitAction::BackToLobby;
        app.running = false;
        return;
    }
    if (pointInRect(x, y, app.continueRect)) {
        if (app.game.phase == GamePhase::MatchOver) {
            resetMatch(app);
        } else {
            beginNextRound(app);
        }
    }
}

void handleTurnTap(App& app, float x, float y) {
    if (app.menuOpen) {
        if (pointInRect(x, y, app.menuCloseRect)) {
            playSound(app, SoundEffect::UiTap);
            app.menuOpen = false;
            return;
        }
        if (pointInRect(x, y, app.soundToggleRect)) {
            const bool wasEnabled = app.audioEnabled;
            app.audioEnabled = !app.audioEnabled;
            if (!wasEnabled && app.audioEnabled) {
                playSound(app, SoundEffect::UiTap);
            } else if (!app.audioEnabled) {
                for (SDL_AudioStream* stream : app.activeAudioStreams) {
                    SDL_DestroyAudioStream(stream);
                }
                app.activeAudioStreams.clear();
            }
            return;
        }
        if (pointInRect(x, y, app.menuLobbyRect)) {
            playSound(app, SoundEffect::UiTap);
            app.exitAction = ScopaExitAction::BackToLobby;
            app.running = false;
            return;
        }
        if (pointInRect(x, y, app.menuNewGameRect)) {
            playSound(app, SoundEffect::UiTap);
            app.menuOpen = false;
            resetMatch(app);
            return;
        }
        app.menuOpen = false;
        return;
    }

    if (pointInRect(x, y, app.menuRect)) {
        playSound(app, SoundEffect::UiTap);
        app.menuOpen = true;
        return;
    }

    if (app.dealing || !app.playFlights.empty() || app.pauseForEffectTimer > 0.0f || app.pendingHandDeal) {
        return;
    }

    if (app.game.phase == GamePhase::PlayerChooseCapture) {
        for (std::size_t i = 0; i < app.captureOptionRects.size(); ++i) {
            if (pointInRect(x, y, app.captureOptionRects[i])) {
                playSound(app, SoundEffect::UiTap);
                app.game.highlightedCaptureIndex = static_cast<int>(i);
                if (app.game.selectedHandIndex >= 0) {
                    applyMove(app, 0, static_cast<std::size_t>(app.game.selectedHandIndex), static_cast<int>(i));
                }
                return;
            }
        }
    }

    for (std::size_t i = 0; i < app.playerHandRects.size(); ++i) {
        if (pointInRect(x, y, app.playerHandRects[i])) {
            playSound(app, SoundEffect::UiTap);
            if (app.game.phase == GamePhase::PlayerChooseCapture && app.game.selectedHandIndex == static_cast<int>(i)) {
                app.game.phase = GamePhase::PlayerTurn;
                app.game.selectedHandIndex = -1;
                app.game.validCaptures.clear();
                app.game.statusMessage = "Your turn";
                return;
            }
            choosePlayerCard(app, static_cast<int>(i));
            return;
        }
    }
}

void handlePointerUp(App& app, float x, float y) {
    if (app.game.phase == GamePhase::RoundSummary || app.game.phase == GamePhase::MatchOver) {
        handleOverlayTap(app, x, y);
        return;
    }

    if (app.game.phase == GamePhase::PlayerTurn || app.game.phase == GamePhase::PlayerChooseCapture) {
        handleTurnTap(app, x, y);
    }
}

bool init(App& app, const AppWindowState& initialWindowState) {
    SDL_SetAppMetadata("Scopa", "0.1.0", "com.gamestudio.scopa");
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO)) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return false;
    }

    app.window = SDL_CreateWindow("Scopa", kBaseWidth, kBaseHeight, SDL_WINDOW_RESIZABLE);
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
    app.audioDevice = SDL_OpenAudioDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, nullptr);
    if (!app.audioDevice) {
        SDL_Log("SDL_OpenAudioDevice failed: %s", SDL_GetError());
    } else {
        SDL_ResumeAudioDevice(app.audioDevice);
    }
    g_cardAssetRoot = findCardAssetRoot();
    g_avatarAssetRoot = findAvatarAssetRoot();
    g_soundAssetRoot = findSoundAssetRoot();
    resetMatch(app);
    return true;
}

void shutdown(App& app) {
    for (SDL_AudioStream* stream : app.activeAudioStreams) {
        SDL_DestroyAudioStream(stream);
    }
    app.activeAudioStreams.clear();
    for (auto& [_, sound] : g_soundCache) {
        SDL_free(sound.data);
    }
    g_soundCache.clear();
    destroyTextures();
    if (app.renderer) {
        SDL_DestroyRenderer(app.renderer);
    }
    if (app.window) {
        SDL_DestroyWindow(app.window);
    }
    if (app.audioDevice) {
        SDL_CloseAudioDevice(app.audioDevice);
    }
    SDL_Quit();
}

}  // namespace

ScopaRunResult runScopaApp(const AppWindowState& initialWindowState) {
    App app;
    if (!init(app, initialWindowState)) {
        shutdown(app);
        return ScopaRunResult{ScopaExitAction::Quit, initialWindowState};
    }

    std::uint64_t lastTicks = SDL_GetTicks();
    while (app.running) {
        const std::uint64_t nowTicks = SDL_GetTicks();
        const float delta = std::min(0.033f, static_cast<float>(nowTicks - lastTicks) / 1000.0f);
        lastTicks = nowTicks;

        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                app.exitAction = ScopaExitAction::Quit;
                app.running = false;
            } else if (event.type == SDL_EVENT_KEY_DOWN) {
                if (event.key.key == SDLK_ESCAPE) {
                    app.exitAction = ScopaExitAction::Quit;
                    app.running = false;
                }
            } else if (event.type == SDL_EVENT_MOUSE_BUTTON_UP) {
                if (event.button.which == SDL_TOUCH_MOUSEID) {
                    continue;
                }
                const SDL_FPoint logical = windowToLogical(app.renderer, event.button.x, event.button.y);
                handlePointerUp(app, logical.x, logical.y);
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

        updateApp(app, delta);
        drawApp(app);
        SDL_Delay(16);
    }

    app.windowState = snapshotWindowState(app.window);
    const ScopaRunResult result{app.exitAction, app.windowState};
    shutdown(app);
    return result;
}