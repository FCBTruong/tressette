#include "tressette_game.h"

#include <SDL3/SDL.h>
#include <SDL3_image/SDL_image.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
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
constexpr float kHandCardW = 72.0f;
constexpr float kHandCardH = 107.0f;
constexpr float kCompareCardW = 58.0f;
constexpr float kCompareCardH = 86.0f;
constexpr SDL_FRect kCompareBox{18.0f, 250.0f, kBaseWidth - 36.0f, 205.0f};
constexpr const char* kCardStyle = "classic";
constexpr int kMatchWinThirds = 63;

enum class Suit : int { Denari, Coppe, Spade, Bastoni };
enum class CardFaceState { Down, Up };
enum class SoundEffect : int { Shuffle, Deal, Draw, Play, MyTurn, CompareWin, CompareLose, UiTap, WinGame, LoseGame };

struct LoadedSound {
    SDL_AudioSpec spec{};
    Uint8* data = nullptr;
    Uint32 length = 0;
};

struct Card {
    Suit suit{};
    int rank{};
    int id{};
};

struct CardView {
    int id = -1;
    SDL_FRect rect{};
    CardFaceState faceState = CardFaceState::Down;
    bool canPlay = false;
    bool hintVisible = false;
    bool recommendPlay = true;
    bool starVisible = false;
    bool isPlayed = false;
    int defaultZIndex = 0;
    float flipScaleX = 1.0f;

    void setCard(int cardId) { id = cardId; }
    int getCardId() const { return id; }
    void setDefaultZIndex(int z) { defaultZIndex = z; }
    void turnFaceDown() { faceState = CardFaceState::Down; }
    void turnFaceUp() { faceState = CardFaceState::Up; }
    void showCard() { turnFaceUp(); }
    void hideCard() { turnFaceDown(); }
    void updateStateCanPlay(bool isValid) { canPlay = isValid; }
    void recommend(bool shouldPlay = true) {
        hintVisible = true;
        recommendPlay = shouldPlay;
    }
    void clearRecommend() { hintVisible = false; }
    void setStar() { starVisible = true; }
    bool hitTest(float x, float y) const;
    void draw(SDL_Renderer* renderer) const;
};

struct CardHit {
    SDL_FRect rect{};
    std::size_t handIndex{};
};

struct CardFlight {
    Card card{};
    int player = 0;
    SDL_FRect from{};
    SDL_FRect to{};
    float elapsed = 0.0f;
    float duration = 0.34f;
};

struct DealFlight {
    Card card{};
    int player = 0;
    std::size_t handIndex = 0;
    SDL_FRect from{};
    SDL_FRect to{};
    float elapsed = 0.0f;
    float delay = 0.0f;
    float duration = 0.32f;
    bool done = false;
};

struct DrawFlight {
    Card card{};
    int player = 0;
    SDL_FRect from{};
    SDL_FRect reveal{};
    SDL_FRect to{};
    float elapsed = 0.0f;
    float delay = 0.0f;
    float duration = 1.35f;
    bool soundPlayed = false;
    bool done = false;
};

struct StockFlight {
    SDL_FRect from{};
    SDL_FRect to{};
    float elapsed = 0.0f;
    float duration = 0.42f;
    bool active = false;
};

struct ScorePopup {
    std::string text;
    int player = 0;
    SDL_FRect from{};
    SDL_FRect to{};
    float elapsed = 0.0f;
    float duration = 0.72f;
};

struct TrickCollectFlight {
    Card card{};
    int owner = 0;
    SDL_FRect from{};
    SDL_FRect to{};
    float elapsed = 0.0f;
    float duration = 0.42f;
};

struct FireworkParticle {
    SDL_FPoint position{};
    SDL_FPoint velocity{};
    float elapsed = 0.0f;
    float duration = 1.1f;
    std::uint8_t r = 255;
    std::uint8_t g = 220;
    std::uint8_t b = 140;
};

struct RainParticle {
    SDL_FPoint position{};
    SDL_FPoint velocity{};
    float elapsed = 0.0f;
    float duration = 1.0f;
    float length = 18.0f;
};

struct Game {
    std::vector<Card> deck;
    std::array<std::vector<Card>, 4> hand;
    std::vector<Card> trick;
    std::vector<int> trickOwner;
    std::array<int, 2> points{0, 0};
    int playerCount = 2;
    int turn = 0;
    int lead = 0;
    int dealer = 1;
    int tricksPlayed = 0;
    bool roundOver = false;
    std::string message = "Tap a card to play";
};

struct App {
    SDL_Window* window = nullptr;
    SDL_Renderer* renderer = nullptr;
    SDL_AudioDeviceID audioDevice = 0;
    Game game;
    std::vector<CardHit> playerHits;
    std::vector<CardFlight> flights;
    std::vector<DealFlight> dealFlights;
    std::vector<DrawFlight> drawFlights;
    std::vector<ScorePopup> scorePopups;
    std::vector<TrickCollectFlight> trickCollectFlights;
    std::vector<FireworkParticle> fireworkParticles;
    std::vector<RainParticle> rainParticles;
    std::vector<SDL_AudioStream*> activeAudioStreams;
    SDL_FRect menuRect{};
    SDL_FRect newGameRect{};
    SDL_FRect mode1v1Rect{};
    SDL_FRect mode2v2Rect{};
    SDL_FRect soundToggleRect{};
    SDL_FRect exitRect{};
    SDL_FRect menuCloseRect{};
    SDL_FRect matchNewGameRect{};
    SDL_FRect matchLobbyRect{};
    std::mt19937 rng{std::random_device{}()};
    float time = 0.0f;
    float botDelay = -1.0f;
    float compareDelay = -1.0f;
    float roundTransitionDelay = -1.0f;
    float fireworkSpawnTimer = 0.0f;
    float menuElapsed = 0.0f;
    float matchOverElapsed = 0.0f;
    int compareWinner = -1;
    int pendingTrickWinner = -1;
    int pendingTrickPoints = 0;
    std::array<std::size_t, 4> dealtCount{0, 0, 0, 0};
    StockFlight stockFlight{};
    bool dealing = false;
    bool drawingCards = false;
    bool collectingTrick = false;
    bool menuOpen = false;
    bool modePickerOpen = false;
    bool audioEnabled = true;
    bool stockVisible = true;
    bool running = true;
    bool matchOver = false;
    int roundNumber = 1;
    int matchWinnerTeam = -1;
    TressetteExitAction exitAction = TressetteExitAction::Quit;
    AppWindowState windowState{};
};

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

std::unordered_map<std::string, SDL_Texture*> g_textureCache;
std::unordered_map<int, LoadedSound> g_soundCache;
std::filesystem::path g_cardAssetRoot;
std::filesystem::path g_lightAssetRoot;
std::filesystem::path g_avatarAssetRoot;
std::filesystem::path g_soundAssetRoot;

std::vector<SDL_FRect> handLayout(std::size_t count, float y, float width, float cardW = kCardW, float cardH = kCardH);
std::vector<SDL_FRect> twoRowHandLayout(std::size_t count, float y, float width);
SDL_FRect avatarRectForPlayer(int player, int playerCount);
std::vector<SDL_FRect> opponentHandLayout(const Game& game, int player);
float debugTextWidth(const std::string& value);
int resolvedMatchWinnerTeam(const Game& game);
void spawnFireworkBurst(App& app, float x, float y);
void spawnRainBurst(App& app, float x);
void handlePointerDown(App& app, float x, float y);

const char* suitName(Suit suit) {
    switch (suit) {
        case Suit::Denari: return "Denari";
        case Suit::Coppe: return "Coppe";
        case Suit::Spade: return "Spade";
        case Suit::Bastoni: return "Bastoni";
    }
    return "";
}

const char* suitShort(Suit suit) {
    switch (suit) {
        case Suit::Denari: return "D";
        case Suit::Coppe: return "C";
        case Suit::Spade: return "S";
        case Suit::Bastoni: return "B";
    }
    return "";
}

std::string rankName(int rank) {
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

Card cardFromId(int cardId) {
    return Card{suitFromId(cardId), rankFromId(cardId), cardId};
}

int trickPower(int rank) {
    switch (rank) {
        case 3: return 10;
        case 2: return 9;
        case 1: return 8;
        case 10: return 7;
        case 9: return 6;
        case 8: return 5;
        case 7: return 4;
        case 6: return 3;
        case 5: return 2;
        case 4: return 1;
        default: return 0;
    }
}

int cardPoints(int rank) {
    if (rank == 1) return 3;
    if (rank == 2 || rank == 3 || rank >= 8) return 1;
    return 0;
}

std::string cardLabel(const Card& card) {
    return rankName(card.rank) + suitShort(card.suit);
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

std::filesystem::path findLightAssetRoot() {
#ifdef __ANDROID__
    return std::filesystem::path{"images/lights"};
#else
    const std::array<std::filesystem::path, 4> candidates{
        std::filesystem::path{"assets/images/lights"},
        std::filesystem::path{"../client/assets/images/lights"},
        std::filesystem::path{"../../client/assets/images/lights"},
        std::filesystem::current_path() / "assets/images/lights",
    };

    for (const auto& candidate : candidates) {
        std::error_code ec;
        const auto full = std::filesystem::weakly_canonical(candidate, ec);
        const auto checkPath = ec ? candidate : full;
        if (std::filesystem::exists(checkPath / "light_03.png") &&
            std::filesystem::exists(checkPath / "light_04.png")) {
            return checkPath;
        }
    }
    return {};
#endif
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

std::filesystem::path cardTexturePath(int cardId) {
    if (std::string(kCardStyle) == "modern") {
        return g_cardAssetRoot / "modern" / ("card_" + std::to_string(cardId) + ".png");
    }
    return g_cardAssetRoot / "classic" / (std::to_string(cardId) + ".png");
}

std::filesystem::path cardBackTexturePath() {
    return g_cardAssetRoot / "card_back.png";
}

std::filesystem::path lightTexturePath(const std::string& fileName) {
    return g_lightAssetRoot / fileName;
}

std::filesystem::path avatarTexturePath(int player) {
    constexpr std::array<int, 4> avatarIds{1, 7, 13, 18};
    return g_avatarAssetRoot / ("avatar_" + std::to_string(avatarIds[static_cast<std::size_t>(player) % avatarIds.size()]) + ".png");
}

std::filesystem::path avatarBorderTexturePath() {
    return g_avatarAssetRoot / "avatar_border.png";
}

std::filesystem::path avatarMaskTexturePath() {
    return g_avatarAssetRoot / "avatar_mask.png";
}

std::filesystem::path soundPath(SoundEffect effect) {
    switch (effect) {
        case SoundEffect::Shuffle: return g_soundAssetRoot / "shuffle_card_sound.wav";
        case SoundEffect::Deal: return g_soundAssetRoot / "deal_card_sound.wav";
        case SoundEffect::Draw: return g_soundAssetRoot / "flip_card.wav";
        case SoundEffect::Play: return g_soundAssetRoot / "play_card.wav";
        case SoundEffect::MyTurn: return g_soundAssetRoot / "your_turn_sound.wav";
        case SoundEffect::CompareWin: return g_soundAssetRoot / "win_turn_sound.wav";
        case SoundEffect::CompareLose: return g_soundAssetRoot / "lose_sound.wav";
        case SoundEffect::UiTap: return g_soundAssetRoot / "touch_sound.wav";
        case SoundEffect::WinGame: return g_soundAssetRoot / "win_game_sound.wav";
        case SoundEffect::LoseGame: return g_soundAssetRoot / "lose_game_sound.wav";
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
    g_textureCache[key] = texture;
    return texture;
}

LoadedSound* loadSound(App& app, SoundEffect effect) {
    if (!app.audioDevice) return nullptr;
    const int key = static_cast<int>(effect);
    if (auto it = g_soundCache.find(key); it != g_soundCache.end()) {
        return &it->second;
    }

    const auto path = soundPath(effect);
    if (path.empty()) return nullptr;

    LoadedSound sound;
    if (!SDL_LoadWAV(path.string().c_str(), &sound.spec, &sound.data, &sound.length)) {
        SDL_Log("SDL_LoadWAV failed for %s: %s", path.string().c_str(), SDL_GetError());
        return nullptr;
    }
    auto [it, inserted] = g_soundCache.emplace(key, sound);
    return inserted ? &it->second : nullptr;
}

void playSound(App& app, SoundEffect effect) {
    if (!app.audioEnabled || !app.audioDevice) return;
    LoadedSound* sound = loadSound(app, effect);
    if (!sound || !sound->data || sound->length == 0) return;

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

void notifyMyTurn(App& app) {
    if (!app.game.roundOver && app.game.turn == 0) {
        playSound(app, SoundEffect::MyTurn);
    }
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

bool pointInRect(float x, float y, const SDL_FRect& rect) {
    return x >= rect.x && x <= rect.x + rect.w && y >= rect.y && y <= rect.y + rect.h;
}

int teamOf(int player) {
    return player % 2;
}

bool isLocalTeam(int player) {
    return teamOf(player) == 0;
}

int nextPlayer(const Game& game, int player) {
    return (player + 1) % game.playerCount;
}

bool allHandsEmpty(const Game& game) {
    for (int p = 0; p < game.playerCount; ++p) {
        if (!game.hand[p].empty()) return false;
    }
    return true;
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

float easeOutBack(float t) {
    t = std::clamp(t, 0.0f, 1.0f);
    constexpr float c1 = 1.70158f;
    constexpr float c3 = c1 + 1.0f;
    const float inv = t - 1.0f;
    return 1.0f + c3 * inv * inv * inv + c1 * inv * inv;
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

SDL_FRect mapRectToPanel(const SDL_FRect& basePanel, const SDL_FRect& panel, const SDL_FRect& rect) {
    const float scaleX = panel.w / basePanel.w;
    const float scaleY = panel.h / basePanel.h;
    return SDL_FRect{
        panel.x + (rect.x - basePanel.x) * scaleX,
        panel.y + (rect.y - basePanel.y) * scaleY,
        rect.w * scaleX,
        rect.h * scaleY,
    };
}

SDL_FPoint mapPointToPanel(const SDL_FRect& basePanel, const SDL_FRect& panel, const SDL_FPoint& point) {
    const float scaleX = panel.w / basePanel.w;
    const float scaleY = panel.h / basePanel.h;
    return SDL_FPoint{
        panel.x + (point.x - basePanel.x) * scaleX,
        panel.y + (point.y - basePanel.y) * scaleY,
    };
}

SDL_FRect trickSlotRect(std::size_t slot, int totalSlots) {
    const float gap = 24.0f;
    const float count = static_cast<float>(totalSlots);
    const float totalW = kCompareCardW * count + gap * (count - 1.0f);
    const float startX = (kBaseWidth - totalW) * 0.5f;
    const float x = startX + static_cast<float>(slot) * (kCompareCardW + gap);
    const float y = kCompareBox.y + (kCompareBox.h - kCompareCardH) * 0.5f;
    return SDL_FRect{x, y, kCompareCardW, kCompareCardH};
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

std::vector<Card> makeDeck() {
    std::vector<Card> deck;
    deck.reserve(40);
    for (int id = 0; id < 40; ++id) {
        deck.push_back(cardFromId(id));
    }
    return deck;
}

void sortHand(std::vector<Card>& hand) {
    std::sort(hand.begin(), hand.end(), [](const Card& a, const Card& b) {
        if (a.suit != b.suit) return static_cast<int>(a.suit) < static_cast<int>(b.suit);
        return trickPower(a.rank) > trickPower(b.rank);
    });
}

bool hasSuit(const std::vector<Card>& hand, Suit suit) {
    return std::any_of(hand.begin(), hand.end(), [suit](const Card& card) {
        return card.suit == suit;
    });
}

bool canPlay(const Game& game, int player, const Card& card) {
    if (game.roundOver || game.turn != player) return false;
    if (game.trick.empty()) return true;
    const Suit leadSuit = game.trick.front().suit;
    return card.suit == leadSuit || !hasSuit(game.hand[player], leadSuit);
}

int winnerOfTrick(const Game& game) {
    int winnerSlot = 0;
    const Suit leadSuit = game.trick.front().suit;
    for (std::size_t i = 1; i < game.trick.size(); ++i) {
        if (game.trick[i].suit == leadSuit &&
            trickPower(game.trick[i].rank) > trickPower(game.trick[winnerSlot].rank)) {
            winnerSlot = static_cast<int>(i);
        }
    }
    return game.trickOwner[winnerSlot];
}

int currentTrickPoints(const Game& game) {
    int trickPoints = 0;
    for (const Card& card : game.trick) {
        trickPoints += cardPoints(card.rank);
    }
    if (game.deck.empty() && allHandsEmpty(game)) {
        trickPoints += 1;
    }
    return trickPoints;
}

SDL_FRect stockSourceRect() {
    return SDL_FRect{kBaseWidth * 0.5f - kCardW * 0.5f, 390.0f, kCardW, kCardH};
}

std::string trickPointsLabel(int points) {
    if (points <= 0) return "0";
    const int whole = points / 3;
    const int thirds = points % 3;
    if (thirds == 0) return std::to_string(whole);
    if (whole == 0) return std::to_string(thirds) + "/3";
    return std::to_string(whole) + " " + std::to_string(thirds) + "/3";
}

std::string matchScoreLabel(const std::string& teamName, int points) {
    return teamName + " " + trickPointsLabel(points);
}

SDL_FRect trickCollectTargetRect(int player, int playerCount) {
    const SDL_FRect avatarRect = avatarRectForPlayer(player, playerCount);
    return SDL_FRect{
        avatarRect.x + avatarRect.w * 0.5f - 18.0f,
        avatarRect.y + avatarRect.h * 0.5f - 26.0f,
        36.0f,
        52.0f,
    };
}

void spawnScorePopup(App& app, int player, int points) {
    if (points <= 0) return;

    const SDL_FRect avatarRect = avatarRectForPlayer(player, app.game.playerCount);
    const std::string label = trickPointsLabel(points);
    const float popupWidth = std::max(56.0f, debugTextWidth(label) + 18.0f);
    const float popupX = avatarRect.x + avatarRect.w * 0.5f - popupWidth * 0.5f;
    const SDL_FRect startRect{popupX, avatarRect.y - 10.0f, popupWidth, 24.0f};
    const SDL_FRect targetRect{popupX, avatarRect.y - 34.0f, popupWidth, 24.0f};
    app.scorePopups.push_back(ScorePopup{label, player, startRect, targetRect});
}

void finishTrick(Game& game) {
    const int winner = winnerOfTrick(game);
    int trickPoints = currentTrickPoints(game);
    ++game.tricksPlayed;
    if (game.deck.empty() && allHandsEmpty(game)) {
        game.roundOver = true;
    }
    game.points[teamOf(winner)] += trickPoints;
    game.message = (isLocalTeam(winner) ? "Your team wins trick" : "Opponent team wins trick");
    game.trick.clear();
    game.trickOwner.clear();
    game.turn = winner;
    game.lead = winner;
    if (game.roundOver) {
        if (game.points[0] == game.points[1]) {
            game.message = "Round draw. Next round...";
        } else if (game.points[0] > game.points[1]) {
            game.message = "Your team wins the round. Next round...";
        } else {
            game.message = "Opponent wins the round. Next round...";
        }
    }
}

std::size_t chooseAutoCard(const Game& game, int player) {
    const auto& hand = game.hand[player];
    if (game.trick.empty()) {
        return static_cast<std::size_t>(std::min_element(hand.begin(), hand.end(), [](const Card& a, const Card& b) {
            if (cardPoints(a.rank) != cardPoints(b.rank)) return cardPoints(a.rank) < cardPoints(b.rank);
            return trickPower(a.rank) < trickPower(b.rank);
        }) - hand.begin());
    }

    const Suit leadSuit = game.trick.front().suit;
    std::vector<std::size_t> legal;
    for (std::size_t i = 0; i < hand.size(); ++i) {
        if (canPlay(game, player, hand[i])) legal.push_back(i);
    }

    const int leadPower = trickPower(game.trick.front().rank);
    auto winning = std::min_element(legal.begin(), legal.end(), [&](std::size_t a, std::size_t b) {
        const Card& ca = hand[a];
        const Card& cb = hand[b];
        const int pa = ca.suit == leadSuit && trickPower(ca.rank) > leadPower ? trickPower(ca.rank) : 100;
        const int pb = cb.suit == leadSuit && trickPower(cb.rank) > leadPower ? trickPower(cb.rank) : 100;
        return pa < pb;
    });
    if (winning != legal.end() && hand[*winning].suit == leadSuit && trickPower(hand[*winning].rank) > leadPower) {
        return *winning;
    }

    return *std::min_element(legal.begin(), legal.end(), [&](std::size_t a, std::size_t b) {
        if (cardPoints(hand[a].rank) != cardPoints(hand[b].rank)) return cardPoints(hand[a].rank) < cardPoints(hand[b].rank);
        return trickPower(hand[a].rank) < trickPower(hand[b].rank);
    });
}

void newDeal(App& app, int playerCount = -1, bool advanceRound = false) {
    Game& game = app.game;
    const int modePlayerCount = playerCount > 0 ? playerCount : game.playerCount;
    const auto carriedPoints = advanceRound ? game.points : std::array<int, 2>{0, 0};
    const int previousDealer = game.dealer;
    if (advanceRound) {
        ++app.roundNumber;
    } else {
        app.roundNumber = 1;
    }
    game = Game{};
    game.playerCount = modePlayerCount;
    app.flights.clear();
    app.dealFlights.clear();
    app.drawFlights.clear();
    app.scorePopups.clear();
    app.trickCollectFlights.clear();
    app.fireworkParticles.clear();
    app.rainParticles.clear();
    app.botDelay = -1.0f;
    app.compareDelay = -1.0f;
    app.roundTransitionDelay = -1.0f;
    app.fireworkSpawnTimer = 0.0f;
    app.menuElapsed = 0.0f;
    app.matchOverElapsed = 0.0f;
    app.compareWinner = -1;
    app.pendingTrickWinner = -1;
    app.pendingTrickPoints = 0;
    app.dealtCount = {0, 0, 0, 0};
    app.stockFlight = {};
    app.dealing = true;
    app.drawingCards = false;
    app.collectingTrick = false;
    app.stockVisible = false;
    app.matchOver = false;
    app.matchWinnerTeam = -1;
    playSound(app, SoundEffect::Shuffle);
    playSound(app, SoundEffect::Deal);
    game.points = carriedPoints;
    game.deck = makeDeck();
    std::shuffle(game.deck.begin(), game.deck.end(), app.rng);
    game.dealer = advanceRound ? nextPlayer(game, previousDealer) : nextPlayer(game, previousDealer);
    game.turn = nextPlayer(game, game.dealer);
    game.lead = game.turn;

    for (int i = 0; i < 10; ++i) {
        for (int player = 0; player < game.playerCount; ++player) {
            game.hand[player].push_back(game.deck.back());
            game.deck.pop_back();
        }
    }
    for (int player = 0; player < game.playerCount; ++player) {
        sortHand(game.hand[player]);
    }

    const SDL_FRect fromRect = stockSourceRect();
    const auto myRects = twoRowHandLayout(game.hand[0].size(), 612.0f, kBaseWidth);
    for (std::size_t i = 0; i < game.hand[0].size(); ++i) {
        app.dealFlights.push_back(DealFlight{game.hand[0][i], 0, i, fromRect, myRects[i], 0.0f, static_cast<float>(i) * 0.075f});
    }
    for (int player = 1; player < game.playerCount; ++player) {
        const auto rects = opponentHandLayout(game, player);
        for (std::size_t i = 0; i < game.hand[player].size(); ++i) {
            app.dealFlights.push_back(DealFlight{game.hand[player][i], player, i, fromRect, rects[std::min(i, rects.size() - 1)], 0.0f,
                                                static_cast<float>(i) * 0.075f + 0.035f * static_cast<float>(player)});
        }
    }
    game.message = "Dealing cards";
}

void setColor(SDL_Renderer* renderer, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    SDL_SetRenderDrawColor(renderer, r, g, b, a);
}

void text(SDL_Renderer* renderer, float x, float y, const std::string& value) {
    SDL_RenderDebugText(renderer, x, y, value.c_str());
}

float uiTextWidth(const std::string& value, float scale = 1.2f) {
    return debugTextWidth(value) * scale;
}

void uiText(SDL_Renderer* renderer, float x, float y, const std::string& value, float scale = 1.2f,
            std::uint8_t shadowAlpha = 120) {
    (void)shadowAlpha;
    std::uint8_t r = 255;
    std::uint8_t g = 255;
    std::uint8_t b = 255;
    std::uint8_t a = 255;
    SDL_GetRenderDrawColor(renderer, &r, &g, &b, &a);
    const float invScale = 1.0f / scale;
    SDL_SetRenderScale(renderer, scale, scale);
    setColor(renderer, r, g, b, a);
    SDL_RenderDebugText(renderer, x * invScale, y * invScale, value.c_str());
    SDL_SetRenderScale(renderer, 1.0f, 1.0f);
}

float debugTextWidth(const std::string& value) {
    return static_cast<float>(value.size()) * 8.0f;
}

void fillRect(SDL_Renderer* renderer, const SDL_FRect& rect, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    SDL_RenderFillRect(renderer, &rect);
}

void strokeRect(SDL_Renderer* renderer, const SDL_FRect& rect, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    SDL_RenderRect(renderer, &rect);
}

void drawTextureMaterialOutline(SDL_Renderer* renderer, SDL_Texture* texture, const SDL_FRect& rect,
                                float thickness, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    if (!texture) {
        return;
    }

    SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND);
    SDL_SetTextureColorMod(texture, r, g, b);

    constexpr float kPi = 3.1415926535f;
    constexpr int samples = 40;
    const std::array<float, 3> layers{thickness + 1.4f, thickness + 0.65f, thickness};
    const std::array<std::uint8_t, 3> alphas{
        static_cast<std::uint8_t>(a * 0.28f),
        static_cast<std::uint8_t>(a * 0.52f),
        a,
    };

    for (std::size_t layer = 0; layer < layers.size(); ++layer) {
        SDL_SetTextureAlphaMod(texture, alphas[layer]);
        for (int i = 0; i < samples; ++i) {
            const float angle = (kPi * 2.0f * static_cast<float>(i)) / static_cast<float>(samples);
            const float dx = std::cos(angle) * layers[layer];
            const float dy = std::sin(angle) * layers[layer];
            const SDL_FRect outlineRect{rect.x + dx, rect.y + dy, rect.w, rect.h};
            SDL_RenderTexture(renderer, texture, nullptr, &outlineRect);
        }
    }

    SDL_SetTextureColorMod(texture, 255, 255, 255);
    SDL_SetTextureAlphaMod(texture, 255);
}

void fillCircle(SDL_Renderer* renderer, float cx, float cy, float radius, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    const int ir = static_cast<int>(radius);
    for (int dy = -ir; dy <= ir; ++dy) {
        const float halfW = std::sqrt(radius * radius - static_cast<float>(dy * dy));
        SDL_RenderLine(renderer, cx - halfW, cy + static_cast<float>(dy), cx + halfW, cy + static_cast<float>(dy));
    }
}

void strokeCircle(SDL_Renderer* renderer, float cx, float cy, float radius, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    setColor(renderer, r, g, b, a);
    constexpr float kPi = 3.1415926535f;
    constexpr int segments = 64;
    for (int i = 0; i < segments; ++i) {
        const float a0 = static_cast<float>(i) * kPi * 2.0f / segments;
        const float a1 = static_cast<float>(i + 1) * kPi * 2.0f / segments;
        SDL_RenderLine(renderer, cx + std::cos(a0) * radius, cy + std::sin(a0) * radius,
                       cx + std::cos(a1) * radius, cy + std::sin(a1) * radius);
    }
}

void drawTextureCircleMasked(SDL_Renderer* renderer, SDL_Texture* texture, const SDL_FRect& rect) {
    if (!texture) return;

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
        if (x1 <= x0) continue;

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

void drawRotatingWinLight(SDL_Renderer* renderer, const SDL_FRect& cardRect, float time) {
    SDL_Texture* glow = loadTexture(renderer, lightTexturePath("light_04.png"));
    SDL_Texture* rays = loadTexture(renderer, lightTexturePath("light_03.png"));
    if (!glow || !rays) {
        return;
    }

    SDL_SetTextureBlendMode(glow, SDL_BLENDMODE_BLEND);
    SDL_SetTextureBlendMode(rays, SDL_BLENDMODE_BLEND);
    SDL_SetTextureAlphaMod(glow, 175);
    SDL_SetTextureAlphaMod(rays, 220);

    const float cx = cardRect.x + cardRect.w * 0.5f;
    const float cy = cardRect.y + cardRect.h * 0.5f;
    const SDL_FRect glowRect{cx - 108.0f, cy - 108.0f, 216.0f, 216.0f};
    const SDL_FRect raysRect{cx - 86.0f, cy - 86.0f, 172.0f, 172.0f};

    SDL_RenderTextureRotated(renderer, glow, nullptr, &glowRect, time * 28.0, nullptr, SDL_FLIP_NONE);
    SDL_RenderTextureRotated(renderer, rays, nullptr, &raysRect, -time * 72.0, nullptr, SDL_FLIP_NONE);
}

void drawTurnAvatar(SDL_Renderer* renderer, const SDL_FRect& rect, int player, const std::string& label, bool active, float time) {
    if (active) {
        SDL_Texture* glow = loadTexture(renderer, lightTexturePath("light_04.png"));
        SDL_Texture* rays = loadTexture(renderer, lightTexturePath("light_03.png"));
        if (glow && rays) {
            SDL_SetTextureBlendMode(glow, SDL_BLENDMODE_BLEND);
            SDL_SetTextureBlendMode(rays, SDL_BLENDMODE_BLEND);
            SDL_SetTextureColorMod(glow, 255, 206, 108);
            SDL_SetTextureColorMod(rays, 255, 188, 74);
            SDL_SetTextureAlphaMod(glow, 165);
            SDL_SetTextureAlphaMod(rays, 215);
            const float cx = rect.x + rect.w * 0.5f;
            const float cy = rect.y + rect.h * 0.5f;
            const SDL_FRect lightRect{cx - 40.0f, cy - 40.0f, 80.0f, 80.0f};
            const SDL_FRect rayRect{cx - 34.0f, cy - 34.0f, 68.0f, 68.0f};
            SDL_RenderTextureRotated(renderer, glow, nullptr, &lightRect, time * 24.0, nullptr, SDL_FLIP_NONE);
            SDL_RenderTextureRotated(renderer, rays, nullptr, &rayRect, -time * 68.0, nullptr, SDL_FLIP_NONE);
            SDL_SetTextureColorMod(glow, 255, 255, 255);
            SDL_SetTextureColorMod(rays, 255, 255, 255);
            SDL_SetTextureAlphaMod(glow, 255);
            SDL_SetTextureAlphaMod(rays, 255);
        }
    }

    const float cx = rect.x + rect.w * 0.5f;
    const float cy = rect.y + rect.h * 0.5f;
    fillCircle(renderer, cx, cy, rect.w * 0.5f, active ? 78 : 32, active ? 62 : 55, active ? 35 : 58, 245);
    SDL_Texture* avatar = loadTexture(renderer, avatarTexturePath(player));
    SDL_Texture* border = loadTexture(renderer, avatarBorderTexturePath());
    if (avatar) {
        SDL_SetTextureBlendMode(avatar, SDL_BLENDMODE_BLEND);
        SDL_SetTextureColorMod(avatar, active ? 255 : 205, active ? 246 : 205, active ? 228 : 205);
        SDL_FRect avatarRect{rect.x + 1.5f, rect.y + 1.5f, rect.w - 3.0f, rect.h - 3.0f};
        drawTextureCircleMasked(renderer, avatar, avatarRect);
        if (active) {
            fillCircle(renderer, cx, cy, rect.w * 0.5f - 1.5f, 255, 200, 92, 34);
        }
        SDL_SetTextureColorMod(avatar, 255, 255, 255);
    } else {
        setColor(renderer, active ? 35 : 235, active ? 30 : 235, active ? 28 : 235);
        text(renderer, rect.x + 21.0f, rect.y + 18.0f, label);
    }
    if (border) {
        SDL_SetTextureBlendMode(border, SDL_BLENDMODE_BLEND);
        if (active) {
            SDL_SetTextureColorMod(border, 255, 192, 64);
            SDL_SetTextureAlphaMod(border, 255);
        }
        SDL_RenderTexture(renderer, border, nullptr, &rect);
        if (active) {
            SDL_SetTextureColorMod(border, 255, 255, 255);
            SDL_SetTextureAlphaMod(border, 255);
        }
    } else {
        strokeCircle(renderer, cx, cy, rect.w * 0.5f, active ? 255 : 144, active ? 184 : 146, active ? 60 : 151, 255);
    }

    const bool localTeam = isLocalTeam(player);
    const SDL_FRect badge{rect.x + rect.w - 16.0f, rect.y + rect.h - 16.0f, 18.0f, 18.0f};
    fillCircle(renderer, badge.x + 9.0f, badge.y + 9.0f, 9.0f, localTeam ? 42 : 174, localTeam ? 160 : 58, localTeam ? 92 : 58, 255);
    strokeCircle(renderer, badge.x + 9.0f, badge.y + 9.0f, 9.0f, 245, 238, 210, 255);
    setColor(renderer, 245, 245, 230);
    text(renderer, badge.x + 5.0f, badge.y + 5.0f, localTeam ? "T" : "R");
}

void drawCard(SDL_Renderer* renderer, const SDL_FRect& rect, const Card* card, bool back) {
    SDL_Texture* texture = back ? loadTexture(renderer, cardBackTexturePath())
                                : loadTexture(renderer, cardTexturePath(card->id));
    if (texture) {
        SDL_RenderTexture(renderer, texture, nullptr, &rect);
        return;
    }

    fillRect(renderer, rect, back ? 34 : 245, back ? 74 : 239, back ? 115 : 225);

    if (back) {
        fillRect(renderer, SDL_FRect{rect.x + 9, rect.y + 9, rect.w - 18, rect.h - 18}, 47, 110, 176);
        text(renderer, rect.x + 18, rect.y + rect.h * 0.45f, "T");
        return;
    }

    const bool red = card->suit == Suit::Denari || card->suit == Suit::Coppe;
    setColor(renderer, red ? 172 : 31, red ? 43 : 52, red ? 42 : 58);
    text(renderer, rect.x + 8, rect.y + 8, rankName(card->rank));
    text(renderer, rect.x + 8, rect.y + 25, suitShort(card->suit));
    text(renderer, rect.x + rect.w * 0.38f, rect.y + rect.h * 0.45f, cardLabel(*card));
}

bool CardView::hitTest(float x, float y) const {
    return pointInRect(x, y, rect);
}

void CardView::draw(SDL_Renderer* renderer) const {
    SDL_FRect drawRect = rect;
    drawRect.w *= std::max(0.02f, flipScaleX);
    drawRect.x += (rect.w - drawRect.w) * 0.5f;

    SDL_Texture* texture = nullptr;
    if (faceState == CardFaceState::Down || id < 0) {
        texture = loadTexture(renderer, cardBackTexturePath());
    } else {
        texture = loadTexture(renderer, cardTexturePath(id));
    }

    const bool shouldDim = faceState == CardFaceState::Up && !canPlay;
    if (texture && shouldDim) {
        SDL_SetTextureColorMod(texture, 92, 92, 92);
        SDL_SetTextureAlphaMod(texture, 190);
    }

    if (faceState == CardFaceState::Down || id < 0) {
        drawCard(renderer, drawRect, nullptr, true);
    } else {
        const Card card = cardFromId(id);
        drawCard(renderer, drawRect, &card, false);
    }

    if (texture && shouldDim) {
        SDL_SetTextureColorMod(texture, 255, 255, 255);
        SDL_SetTextureAlphaMod(texture, 255);
    }
}

std::vector<SDL_FRect> handLayout(std::size_t count, float y, float width, float cardW, float cardH) {
    std::vector<SDL_FRect> rects;
    if (count == 0) return rects;
    const float margin = 18.0f;
    const float maxSpan = width - margin * 2.0f - cardW;
    const float step = count == 1 ? 0.0f : maxSpan / static_cast<float>(count - 1);
    const float totalW = cardW + step * static_cast<float>(count - 1);
    float x = (width - totalW) * 0.5f;
    for (std::size_t i = 0; i < count; ++i) {
        rects.push_back(SDL_FRect{x + step * static_cast<float>(i), y, cardW, cardH});
    }
    return rects;
}

std::vector<SDL_FRect> twoRowHandLayout(std::size_t count, float y, float width) {
    std::vector<SDL_FRect> rects(count);
    if (count == 0) return rects;

    const std::size_t firstRowCount = (count + 1) / 2;
    const std::size_t secondRowCount = count - firstRowCount;
    const auto firstRow = handLayout(firstRowCount, y, width, kHandCardW, kHandCardH);
    const auto secondRow = handLayout(secondRowCount, y + kHandCardH + 8.0f, width, kHandCardW, kHandCardH);

    for (std::size_t i = 0; i < firstRow.size(); ++i) {
        rects[i] = firstRow[i];
    }
    for (std::size_t i = 0; i < secondRow.size(); ++i) {
        rects[firstRowCount + i] = secondRow[i];
    }
    return rects;
}

bool isBusy(const App& app) {
    return app.matchOver || app.dealing || app.stockFlight.active || app.drawingCards || app.collectingTrick || app.roundTransitionDelay >= 0.0f ||
           !app.flights.empty() || app.compareDelay >= 0.0f || app.botDelay >= 0.0f;
}

SDL_FRect deckRect() {
    return SDL_FRect{kCompareBox.x + 18.0f, kCompareBox.y + (kCompareBox.h - kCardH) * 0.5f, kCardW, kCardH};
}

SDL_FRect avatarRectForPlayer(int player, int playerCount) {
    if (player == 0) return SDL_FRect{kBaseWidth - 74.0f, 552.0f, 52.0f, 52.0f};
    if (playerCount == 2) return SDL_FRect{kBaseWidth - 74.0f, 88.0f, 52.0f, 52.0f};
    if (player == 1) return SDL_FRect{kBaseWidth - 74.0f, kCompareBox.y + kCompareBox.h * 0.5f - 26.0f, 52.0f, 52.0f};
    if (player == 2) return SDL_FRect{kBaseWidth * 0.5f - 26.0f, 88.0f, 52.0f, 52.0f};
    return SDL_FRect{22.0f, kCompareBox.y + kCompareBox.h * 0.5f - 26.0f, 52.0f, 52.0f};
}

std::string avatarLabelForPlayer(int player) {
    if (player == 0) return "Y";
    if (player == 2) return "P";
    return "O";
}

std::vector<SDL_FRect> opponentHandLayout(const Game& game, int player) {
    if (game.playerCount == 2 || player == 2) {
        return handLayout(game.hand[player].size(), 142.0f, kBaseWidth, kCardW, kCardH);
    }

    std::vector<SDL_FRect> rects;
    const float cardW = 38.0f;
    const float cardH = 56.0f;
    const float step = 16.0f;
    const float totalH = cardH + step * static_cast<float>(std::max<std::size_t>(game.hand[player].size(), 1) - 1);
    const float startY = kCompareBox.y + (kCompareBox.h - totalH) * 0.5f;
    const float x = player == 1 ? kBaseWidth - 58.0f : 20.0f;
    for (std::size_t i = 0; i < game.hand[player].size(); ++i) {
        rects.push_back(SDL_FRect{x, startY + step * static_cast<float>(i), cardW, cardH});
    }
    return rects;
}

SDL_FRect nextHandTargetRect(const Game& game, int player) {
    if (player == 0) {
        const auto rects = twoRowHandLayout(game.hand[0].size() + 1, 612.0f, kBaseWidth);
        return rects.empty() ? SDL_FRect{18.0f, 612.0f, kHandCardW, kHandCardH} : rects.back();
    }
    Game copy = game;
    copy.hand[player].push_back(Card{});
    const auto rects = opponentHandLayout(copy, player);
    return rects.empty() ? avatarRectForPlayer(player, game.playerCount) : rects.back();
}

void startDrawCards(App& app, int winner) {
    Game& game = app.game;
    if (game.deck.empty()) {
        if (game.turn != 0) {
            app.botDelay = 0.45f;
        }
        return;
    }

    app.drawingCards = true;
    app.drawFlights.clear();
    game.message = "Drawing cards";

    float delay = 0.0f;
    for (int offset = 0; offset < game.playerCount; ++offset) {
        const int player = (winner + offset) % game.playerCount;
        if (game.deck.empty()) break;
        const Card card = game.deck.back();
        game.deck.pop_back();
        const float revealX = player == 0 ? 186.0f : 232.0f;
        const SDL_FRect revealRect{revealX, 315.0f, kCardW, kCardH};
        app.drawFlights.push_back(DrawFlight{card, player, deckRect(), revealRect, nextHandTargetRect(game, player), 0.0f, delay});
        delay += 0.82f;
    }
}

void startPlayCard(App& app, int player, std::size_t index, const SDL_FRect& fromRect) {
    Game& game = app.game;
    if (index >= game.hand[player].size()) return;

    const Card card = game.hand[player][index];
    if (!canPlay(game, player, card)) {
        game.message = "Must follow suit: " + std::string(suitName(game.trick.front().suit));
        return;
    }

    game.hand[player].erase(game.hand[player].begin() + static_cast<std::ptrdiff_t>(index));
    game.turn = -1;
    game.message = player == 0 ? "Playing card" : "Opponent plays";
    playSound(app, SoundEffect::Play);

    const SDL_FRect target = trickSlotRect(game.trick.size(), game.playerCount);
    app.flights.push_back(CardFlight{card, player, fromRect, target});
}

void startBotCard(App& app) {
    Game& game = app.game;
    if (game.roundOver || game.turn <= 0 || game.turn >= game.playerCount || game.hand[game.turn].empty()) return;

    const int player = game.turn;
    const std::size_t index = chooseAutoCard(game, player);
    auto botRects = opponentHandLayout(game, player);
    const SDL_FRect fromRect = index < botRects.size() ? botRects[index] : avatarRectForPlayer(player, game.playerCount);
    startPlayCard(app, player, index, fromRect);
}

void completeFlight(App& app, const CardFlight& flight) {
    Game& game = app.game;
    game.trick.push_back(flight.card);
    game.trickOwner.push_back(flight.player);

    if (static_cast<int>(game.trick.size()) == game.playerCount) {
        app.compareWinner = winnerOfTrick(game);
        app.compareDelay = 1.15f;
        game.message = isLocalTeam(app.compareWinner) ? "Comparing cards: your team is winning" : "Comparing cards: opponent team is winning";
        if (isLocalTeam(app.compareWinner)) {
            playSound(app, SoundEffect::CompareWin);
        }
        return;
    }

    game.turn = nextPlayer(game, flight.player);
    game.message = game.turn == 0 ? "Your turn" : "Opponent turn";
    if (game.turn != 0) {
        app.botDelay = 0.45f;
    } else {
        notifyMyTurn(app);
    }
}

void startCollectTrick(App& app) {
    app.collectingTrick = true;
    app.trickCollectFlights.clear();
    const SDL_FRect targetRect = trickCollectTargetRect(app.pendingTrickWinner, app.game.playerCount);
    for (std::size_t i = 0; i < app.game.trick.size(); ++i) {
        app.trickCollectFlights.push_back(TrickCollectFlight{
            app.game.trick[i],
            app.game.trickOwner[i],
            trickSlotRect(i, app.game.playerCount),
            targetRect,
        });
    }
    app.game.message = isLocalTeam(app.pendingTrickWinner) ? "Collecting trick for your team" : "Collecting trick for opponents";
}

void updateApp(App& app, float delta) {
    app.time += delta;
    cleanupFinishedAudioStreams(app);
    app.menuElapsed = app.menuOpen ? (app.menuElapsed + delta) : 0.0f;

    if (app.matchOver) {
        app.matchOverElapsed += delta;
        app.fireworkSpawnTimer -= delta;
        if (app.fireworkSpawnTimer <= 0.0f) {
            if (app.matchWinnerTeam == 0) {
                std::uniform_real_distribution<float> xDist(88.0f, kBaseWidth - 88.0f);
                std::uniform_real_distribution<float> yDist(246.0f, 420.0f);
                spawnFireworkBurst(app, xDist(app.rng), yDist(app.rng));
                app.fireworkSpawnTimer = 0.38f;
            } else {
                std::uniform_real_distribution<float> xDist(84.0f, kBaseWidth - 190.0f);
                spawnRainBurst(app, xDist(app.rng));
                app.fireworkSpawnTimer = 0.26f;
            }
        }

        for (std::size_t i = 0; i < app.fireworkParticles.size();) {
            app.fireworkParticles[i].elapsed += delta;
            if (app.fireworkParticles[i].elapsed >= app.fireworkParticles[i].duration) {
                app.fireworkParticles.erase(app.fireworkParticles.begin() + static_cast<std::ptrdiff_t>(i));
            } else {
                ++i;
            }
        }

        for (std::size_t i = 0; i < app.rainParticles.size();) {
            app.rainParticles[i].elapsed += delta;
            if (app.rainParticles[i].elapsed >= app.rainParticles[i].duration) {
                app.rainParticles.erase(app.rainParticles.begin() + static_cast<std::ptrdiff_t>(i));
            } else {
                ++i;
            }
        }
        return;
    }

    for (std::size_t i = 0; i < app.scorePopups.size();) {
        app.scorePopups[i].elapsed += delta;
        if (app.scorePopups[i].elapsed >= app.scorePopups[i].duration) {
            app.scorePopups.erase(app.scorePopups.begin() + static_cast<std::ptrdiff_t>(i));
        } else {
            ++i;
        }
    }

    if (app.dealing) {
        bool allDone = true;
        for (DealFlight& flight : app.dealFlights) {
            if (flight.done) {
                continue;
            }
            allDone = false;
            flight.elapsed += delta;
            if (flight.elapsed >= flight.delay + flight.duration) {
                flight.done = true;
                app.dealtCount[flight.player] = std::max(app.dealtCount[flight.player], flight.handIndex + 1);
            }
        }

        if (allDone) {
            app.dealing = false;
            app.dealFlights.clear();
            for (int player = 0; player < app.game.playerCount; ++player) {
                app.dealtCount[player] = app.game.hand[player].size();
            }
            app.stockFlight = StockFlight{stockSourceRect(), deckRect(), 0.0f, 0.42f, true};
            app.game.message = "Placing remaining cards";
        }
        return;
    }

    if (app.stockFlight.active) {
        app.stockFlight.elapsed += delta;
        if (app.stockFlight.elapsed >= app.stockFlight.duration) {
            app.stockFlight.active = false;
            app.stockVisible = true;
            app.game.message = app.game.turn == 0 ? "Your turn" : "Opponent turn";
            if (app.game.turn != 0) {
                app.botDelay = 0.45f;
            } else {
                notifyMyTurn(app);
            }
        }
        return;
    }

    if (app.collectingTrick) {
        bool allDone = true;
        for (TrickCollectFlight& flight : app.trickCollectFlights) {
            flight.elapsed += delta;
            if (flight.elapsed < flight.duration) {
                allDone = false;
            }
        }

        if (allDone) {
            app.collectingTrick = false;
            app.trickCollectFlights.clear();
            finishTrick(app.game);
            spawnScorePopup(app, app.pendingTrickWinner, app.pendingTrickPoints);
            app.pendingTrickWinner = -1;
            app.pendingTrickPoints = 0;

            if (app.game.points[0] >= kMatchWinThirds || app.game.points[1] >= kMatchWinThirds) {
                app.matchWinnerTeam = resolvedMatchWinnerTeam(app.game);
                app.matchOver = app.matchWinnerTeam >= 0;
                app.game.roundOver = true;
                app.fireworkParticles.clear();
                app.rainParticles.clear();
                app.fireworkSpawnTimer = 0.0f;
                app.matchOverElapsed = 0.0f;
                if (app.matchWinnerTeam == 0) {
                    playSound(app, SoundEffect::WinGame);
                } else if (app.matchWinnerTeam == 1) {
                    playSound(app, SoundEffect::LoseGame);
                }
            } else if (app.game.roundOver) {
                    app.roundTransitionDelay = 1.15f;
            } else if (!app.game.deck.empty()) {
                startDrawCards(app, app.game.turn);
            } else if (app.game.turn != 0) {
                app.botDelay = 0.45f;
            } else {
                notifyMyTurn(app);
            }
        }
        return;
    }

    if (app.drawingCards) {
        bool allDone = true;
        for (DrawFlight& flight : app.drawFlights) {
            if (flight.done) {
                continue;
            }
            allDone = false;
            flight.elapsed += delta;
            if (!flight.soundPlayed && flight.elapsed >= flight.delay) {
                flight.soundPlayed = true;
                playSound(app, SoundEffect::Draw);
            }
            if (flight.elapsed >= flight.delay + flight.duration) {
                flight.done = true;
                app.game.hand[flight.player].push_back(flight.card);
                sortHand(app.game.hand[flight.player]);
            }
        }

        if (allDone) {
            app.drawingCards = false;
            app.drawFlights.clear();
            app.game.message = app.game.turn == 0 ? "Your turn" : "Opponent turn";
            if (!app.game.roundOver && app.game.turn != 0) {
                app.botDelay = 0.45f;
            } else {
                notifyMyTurn(app);
            }
        }
        return;
    }

    for (std::size_t i = 0; i < app.flights.size();) {
        app.flights[i].elapsed += delta;
        if (app.flights[i].elapsed >= app.flights[i].duration) {
            const CardFlight completed = app.flights[i];
            app.flights.erase(app.flights.begin() + static_cast<std::ptrdiff_t>(i));
            completeFlight(app, completed);
        } else {
            ++i;
        }
    }

    if (app.flights.empty() && app.compareDelay >= 0.0f) {
        app.compareDelay -= delta;
        if (app.compareDelay <= 0.0f) {
            app.compareDelay = -1.0f;
            app.pendingTrickWinner = winnerOfTrick(app.game);
            app.pendingTrickPoints = currentTrickPoints(app.game);
            app.compareWinner = -1;
            startCollectTrick(app);
        }
    }

    if (app.roundTransitionDelay >= 0.0f) {
        app.roundTransitionDelay -= delta;
        if (app.roundTransitionDelay <= 0.0f) {
            newDeal(app, app.game.playerCount, true);
        }
        return;
    }

    if (app.flights.empty() && app.compareDelay < 0.0f && app.botDelay >= 0.0f) {
        app.botDelay -= delta;
        if (app.botDelay <= 0.0f) {
            app.botDelay = -1.0f;
            startBotCard(app);
        }
    }
}

void drawButton(SDL_Renderer* renderer, const SDL_FRect& rect, const std::string& label) {
    fillRect(renderer, rect, 228, 179, 70);
    strokeRect(renderer, rect, 63, 45, 26);
    setColor(renderer, 25, 25, 25);
    uiText(renderer, rect.x + 12.0f, rect.y + 12.0f, label);
}

void drawCenteredButtonLabel(SDL_Renderer* renderer, const SDL_FRect& rect, const std::string& label) {
    setColor(renderer, 68, 50, 30);
    uiText(renderer, rect.x + rect.w * 0.5f - uiTextWidth(label) * 0.5f, rect.y + rect.h + 9.0f, label);
}

void drawIconButtonFrame(SDL_Renderer* renderer, const SDL_FRect& rect) {
    fillRect(renderer, rect, 228, 179, 70);
    strokeRect(renderer, rect, 63, 45, 26);
    strokeRect(renderer, SDL_FRect{rect.x + 2.0f, rect.y + 2.0f, rect.w - 4.0f, rect.h - 4.0f}, 246, 221, 145, 150);
}

void drawSoundIconButton(SDL_Renderer* renderer, const SDL_FRect& rect, bool enabled) {
    drawIconButtonFrame(renderer, rect);
    setColor(renderer, 39, 31, 23);

    const SDL_FRect speakerBody{rect.x + 14.0f, rect.y + 20.0f, 9.0f, 18.0f};
    fillRect(renderer, speakerBody, 39, 31, 23);
    const float midY = rect.y + rect.h * 0.5f;
    SDL_RenderLine(renderer, speakerBody.x + speakerBody.w, speakerBody.y + 2.0f, rect.x + 33.0f, midY - 8.0f);
    SDL_RenderLine(renderer, speakerBody.x + speakerBody.w, speakerBody.y + speakerBody.h - 2.0f, rect.x + 33.0f, midY + 8.0f);
    SDL_RenderLine(renderer, rect.x + 33.0f, midY - 8.0f, rect.x + 33.0f, midY + 8.0f);

    if (enabled) {
        SDL_RenderLine(renderer, rect.x + 39.0f, midY - 10.0f, rect.x + 45.0f, midY - 4.0f);
        SDL_RenderLine(renderer, rect.x + 39.0f, midY + 10.0f, rect.x + 45.0f, midY + 4.0f);
        SDL_RenderLine(renderer, rect.x + 42.0f, midY - 14.0f, rect.x + 50.0f, midY - 6.0f);
        SDL_RenderLine(renderer, rect.x + 42.0f, midY + 14.0f, rect.x + 50.0f, midY + 6.0f);
    } else {
        setColor(renderer, 186, 58, 39);
        SDL_RenderLine(renderer, rect.x + 38.0f, rect.y + 18.0f, rect.x + rect.w - 14.0f, rect.y + rect.h - 18.0f);
        SDL_RenderLine(renderer, rect.x + 39.0f, rect.y + 18.0f, rect.x + rect.w - 13.0f, rect.y + rect.h - 18.0f);
    }
}

void drawExitIconButton(SDL_Renderer* renderer, const SDL_FRect& rect) {
    drawIconButtonFrame(renderer, rect);
    setColor(renderer, 150, 41, 28);
    const float midY = rect.y + rect.h * 0.5f;
    SDL_RenderLine(renderer, rect.x + 16.0f, midY, rect.x + rect.w - 16.0f, midY);
    SDL_RenderLine(renderer, rect.x + 16.0f, midY + 1.0f, rect.x + rect.w - 16.0f, midY + 1.0f);
    SDL_RenderLine(renderer, rect.x + 16.0f, midY, rect.x + 26.0f, midY - 8.0f);
    SDL_RenderLine(renderer, rect.x + 16.0f, midY, rect.x + 26.0f, midY + 8.0f);
}

void drawLobbyGameIcon(SDL_Renderer* renderer, const SDL_FRect& rect) {
    const SDL_FRect cardRect{rect.x + rect.w * 0.5f - 24.0f, rect.y + 26.0f, 48.0f, 66.0f};
    fillRect(renderer, cardRect, 243, 237, 222);
    strokeRect(renderer, cardRect, 68, 48, 30);
    setColor(renderer, 175, 42, 38);
    uiText(renderer, cardRect.x + 13.0f, cardRect.y + 20.0f, "3");
    uiText(renderer, cardRect.x + 14.0f, cardRect.y + 41.0f, "C");
}

void drawCloseIconButton(SDL_Renderer* renderer, const SDL_FRect& rect) {
    fillRect(renderer, rect, 236, 225, 193);
    strokeRect(renderer, rect, 63, 45, 26);
    setColor(renderer, 120, 43, 28);
    SDL_RenderLine(renderer, rect.x + 8.0f, rect.y + 8.0f, rect.x + rect.w - 8.0f, rect.y + rect.h - 8.0f);
    SDL_RenderLine(renderer, rect.x + 9.0f, rect.y + 8.0f, rect.x + rect.w - 7.0f, rect.y + rect.h - 8.0f);
    SDL_RenderLine(renderer, rect.x + rect.w - 8.0f, rect.y + 8.0f, rect.x + 8.0f, rect.y + rect.h - 8.0f);
    SDL_RenderLine(renderer, rect.x + rect.w - 9.0f, rect.y + 8.0f, rect.x + 7.0f, rect.y + rect.h - 8.0f);
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

void drawDeckCountBadge(SDL_Renderer* renderer, const SDL_FRect& deck, int count) {
    const std::string value = std::to_string(count);
    const float badgeW = std::max(24.0f, debugTextWidth(value) + 12.0f);
    const SDL_FRect badge{deck.x + (deck.w - badgeW) * 0.5f, deck.y + (deck.h - 20.0f) * 0.5f, badgeW, 20.0f};
    fillRect(renderer, badge, 27, 24, 20, 182);
    strokeRect(renderer, badge, 241, 214, 135, 220);
    setColor(renderer, 249, 241, 216);
    text(renderer, badge.x + (badge.w - debugTextWidth(value)) * 0.5f, badge.y + 5.0f, value);
}

int resolvedMatchWinnerTeam(const Game& game) {
    if (game.points[0] == game.points[1]) {
        return -1;
    }
    return game.points[0] > game.points[1] ? 0 : 1;
}

void drawScorePanel(SDL_Renderer* renderer, const SDL_FRect& rect, const std::string& label,
                    std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    fillRect(renderer, rect, r, g, b, 210);
    strokeRect(renderer, rect, 244, 232, 197, 220);
    setColor(renderer, 255, 248, 226);
    uiText(renderer, rect.x + 10.0f, rect.y + 8.0f, label);
}

void drawCompactScoreBadge(SDL_Renderer* renderer, float x, float y, const std::string& label,
                           std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    const float width = debugTextWidth(label) + 26.0f;
    const SDL_FRect rect{x, y, width, 24.0f};
    fillRect(renderer, rect, r, g, b, 210);
    strokeRect(renderer, rect, 244, 232, 197, 220);
    setColor(renderer, 255, 248, 226);
    uiText(renderer, rect.x + 10.0f, rect.y + 6.0f, label);
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
        const float speed = 44.0f + static_cast<float>((i % 6) * 10);
        const SDL_Color color = palette[static_cast<std::size_t>(i) % palette.size()];
        app.fireworkParticles.push_back(FireworkParticle{
            SDL_FPoint{x, y},
            SDL_FPoint{std::cos(angle) * speed, std::sin(angle) * speed - 18.0f},
            0.0f,
            1.15f,
            color.r,
            color.g,
            color.b,
        });
    }
}

void spawnRainBurst(App& app, float x) {
    for (int i = 0; i < 8; ++i) {
        app.rainParticles.push_back(RainParticle{
            SDL_FPoint{x + static_cast<float>(i * 22), 238.0f - static_cast<float>(i % 3) * 18.0f},
            SDL_FPoint{-16.0f, 210.0f + static_cast<float>((i % 4) * 18)},
            0.0f,
            1.15f,
            18.0f + static_cast<float>(i % 3) * 4.0f,
        });
    }
}

void drawFireworks(App& app) {
    for (const FireworkParticle& particle : app.fireworkParticles) {
        const float t = std::clamp(particle.elapsed / particle.duration, 0.0f, 1.0f);
        const float alphaFactor = 1.0f - t;
        const SDL_FPoint pos{
            particle.position.x + particle.velocity.x * particle.elapsed,
            particle.position.y + particle.velocity.y * particle.elapsed + 20.0f * particle.elapsed * particle.elapsed,
        };
        fillCircle(app.renderer, pos.x, pos.y, 2.2f, particle.r, particle.g, particle.b,
                   static_cast<std::uint8_t>(220.0f * alphaFactor));
    }
}

void drawRainEffect(App& app) {
    for (const RainParticle& particle : app.rainParticles) {
        const float t = std::clamp(particle.elapsed / particle.duration, 0.0f, 1.0f);
        const SDL_FPoint head{
            particle.position.x + particle.velocity.x * particle.elapsed,
            particle.position.y + particle.velocity.y * particle.elapsed,
        };
        const SDL_FPoint tail{head.x + 6.0f, head.y - particle.length};
        const std::uint8_t alpha = static_cast<std::uint8_t>(210.0f * (1.0f - t));
        setColor(app.renderer, 122, 180, 255, alpha);
        SDL_RenderLine(app.renderer, tail.x, tail.y, head.x, head.y);
        SDL_RenderLine(app.renderer, tail.x + 1.0f, tail.y, head.x + 1.0f, head.y);
    }
}

void drawMatchOverOverlay(App& app) {
    fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 3, 7, 14, 165);
    const SDL_FRect basePanel{54.0f, 254.0f, 372.0f, 232.0f};
    const float introT = std::clamp(app.matchOverElapsed / 0.42f, 0.0f, 1.0f);
    const float scale = 0.84f + 0.16f * easeOutBack(introT);
    const SDL_FRect panel{
        basePanel.x + (basePanel.w - basePanel.w * scale) * 0.5f,
        basePanel.y + (basePanel.h - basePanel.h * scale) * 0.5f,
        basePanel.w * scale,
        basePanel.h * scale,
    };
    fillRect(app.renderer, panel, 242, 234, 207, 245);
    strokeRect(app.renderer, panel, 72, 55, 34);

    const std::string title = app.matchWinnerTeam == 0 ? "You Win" : "Opponent Wins";
    const std::string subtitle = app.matchWinnerTeam == 0 ? "Congratulations, you reached 21!" : "The match is over.";
    const SDL_FPoint titlePos = mapPointToPanel(basePanel, panel, SDL_FPoint{basePanel.x + basePanel.w * 0.5f, basePanel.y + 28.0f});
    const SDL_FPoint subtitlePos = mapPointToPanel(basePanel, panel, SDL_FPoint{basePanel.x + basePanel.w * 0.5f, basePanel.y + 56.0f});
    setColor(app.renderer, 42, 34, 26);
    uiText(app.renderer, titlePos.x - uiTextWidth(title) * 0.5f, titlePos.y, title);
    uiText(app.renderer, subtitlePos.x - uiTextWidth(subtitle) * 0.5f, subtitlePos.y, subtitle);

    const std::string youLabel = matchScoreLabel("You", app.game.points[0]);
    const std::string oppLabel = matchScoreLabel("Opp", app.game.points[1]);
    drawScorePanel(app.renderer, mapRectToPanel(basePanel, panel, SDL_FRect{basePanel.x + 34.0f, basePanel.y + 92.0f, basePanel.w - 68.0f, 38.0f}),
                   youLabel, 46, 103, 199);
    drawScorePanel(app.renderer, mapRectToPanel(basePanel, panel, SDL_FRect{basePanel.x + 34.0f, basePanel.y + 138.0f, basePanel.w - 68.0f, 38.0f}),
                   oppLabel, 171, 54, 54);

    app.matchNewGameRect = mapRectToPanel(basePanel, panel, SDL_FRect{basePanel.x + 42.0f, basePanel.y + 184.0f, 126.0f, 36.0f});
    app.matchLobbyRect = mapRectToPanel(basePanel, panel, SDL_FRect{basePanel.x + basePanel.w - 168.0f, basePanel.y + 184.0f, 126.0f, 36.0f});
    drawButton(app.renderer, app.matchNewGameRect, "New Game");
    drawButton(app.renderer, app.matchLobbyRect, "Lobby");
}

void drawMenuOverlay(App& app) {
    fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 0, 0, 0, 130);
    const SDL_FRect basePanel{82.0f, 232.0f, 316.0f, 260.0f};
    const float introT = std::clamp(app.menuElapsed / 0.28f, 0.0f, 1.0f);
    const float scale = 0.88f + 0.12f * easeOutBack(introT);
    const SDL_FRect panel{
        basePanel.x + (basePanel.w - basePanel.w * scale) * 0.5f,
        basePanel.y + (basePanel.h - basePanel.h * scale) * 0.5f,
        basePanel.w * scale,
        basePanel.h * scale,
    };
    app.menuCloseRect = mapRectToPanel(basePanel, panel, SDL_FRect{basePanel.x + basePanel.w - 38.0f, basePanel.y + 12.0f, 26.0f, 26.0f});
    fillRect(app.renderer, panel, 242, 234, 207, 248);
    strokeRect(app.renderer, panel, 72, 55, 34);
    setColor(app.renderer, 42, 34, 26);
    const std::string title = app.modePickerOpen ? "New Game" : "Menu";
    const SDL_FPoint titlePos = mapPointToPanel(basePanel, panel, SDL_FPoint{basePanel.x + 24.0f, basePanel.y + 22.0f});
    uiText(app.renderer, titlePos.x, titlePos.y, title);
    drawCloseIconButton(app.renderer, app.menuCloseRect);

    if (!app.modePickerOpen) {
        app.newGameRect = mapRectToPanel(basePanel, panel, SDL_FRect{basePanel.x + 42.0f, basePanel.y + 82.0f, basePanel.w - 84.0f, 44.0f});
        app.soundToggleRect = mapRectToPanel(basePanel, panel, SDL_FRect{basePanel.x + 74.0f, basePanel.y + 154.0f, 60.0f, 60.0f});
        app.exitRect = mapRectToPanel(basePanel, panel, SDL_FRect{basePanel.x + basePanel.w - 134.0f, basePanel.y + 154.0f, 60.0f, 60.0f});
        drawButton(app.renderer, app.newGameRect, "New Game");
        drawSoundIconButton(app.renderer, app.soundToggleRect, app.audioEnabled);
        drawExitIconButton(app.renderer, app.exitRect);
        drawCenteredButtonLabel(app.renderer, app.soundToggleRect, app.audioEnabled ? "Sound" : "Muted");
        drawCenteredButtonLabel(app.renderer, app.exitRect, "Lobby");
        return;
    }

    app.mode1v1Rect = mapRectToPanel(basePanel, panel, SDL_FRect{basePanel.x + 42.0f, basePanel.y + 76.0f, basePanel.w - 84.0f, 44.0f});
    app.mode2v2Rect = mapRectToPanel(basePanel, panel, SDL_FRect{basePanel.x + 42.0f, basePanel.y + 136.0f, basePanel.w - 84.0f, 44.0f});
    app.soundToggleRect = SDL_FRect{0.0f, 0.0f, 0.0f, 0.0f};
    app.exitRect = SDL_FRect{0.0f, 0.0f, 0.0f, 0.0f};
    drawButton(app.renderer, app.mode1v1Rect, "1v1");
    drawButton(app.renderer, app.mode2v2Rect, "2v2");
    setColor(app.renderer, 84, 70, 52);
    const SDL_FPoint notePos = mapPointToPanel(basePanel, panel, SDL_FPoint{basePanel.x + 42.0f, basePanel.y + 204.0f});
    uiText(app.renderer, notePos.x, notePos.y, "2v2: You + Partner vs Opponents");
}

void render(App& app) {
    int outW = 0;
    int outH = 0;
    SDL_GetRenderOutputSize(app.renderer, &outW, &outH);
    SDL_SetRenderLogicalPresentation(app.renderer, kBaseWidth, kBaseHeight, SDL_LOGICAL_PRESENTATION_LETTERBOX);

    fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 24, 116, 77);
    fillRect(app.renderer, kCompareBox, 35, 139, 87);
    strokeRect(app.renderer, kCompareBox, 208, 177, 100);

    app.menuRect = SDL_FRect{kBaseWidth - 72.0f, 18.0f, 54.0f, 36.0f};
    drawMenuIconButton(app.renderer, app.menuRect);

    setColor(app.renderer, 240, 240, 225);
    uiText(app.renderer, 18, 22, app.game.message);
    drawCompactScoreBadge(app.renderer, 18.0f, 48.0f, matchScoreLabel("You", app.game.points[0]), 46, 103, 199);
    drawCompactScoreBadge(app.renderer, 250.0f, 48.0f, matchScoreLabel("Opp", app.game.points[1]), 171, 54, 54);
    uiText(app.renderer, 18, 74, "Round " + std::to_string(app.roundNumber) + "  Turn " + (app.game.turn == 0 ? "You" : "Opponent"));

    const bool inputLocked = app.dealing || app.stockFlight.active || app.drawingCards || app.collectingTrick ||
                             !app.flights.empty() || app.compareDelay >= 0.0f || app.roundTransitionDelay >= 0.0f;
    for (int player = 0; player < app.game.playerCount; ++player) {
        drawTurnAvatar(app.renderer, avatarRectForPlayer(player, app.game.playerCount), player, avatarLabelForPlayer(player),
                       app.game.turn == player && !inputLocked, app.time);
    }

    if (app.stockFlight.active) {
        CardView stockFlightView;
        stockFlightView.rect = lerpRect(app.stockFlight.from, app.stockFlight.to,
                                        std::clamp(app.stockFlight.elapsed / app.stockFlight.duration, 0.0f, 1.0f));
        stockFlightView.turnFaceDown();
        stockFlightView.draw(app.renderer);
    }

    if (app.stockVisible && (!app.game.deck.empty() || app.drawingCards)) {
        CardView stockView;
        stockView.rect = deckRect();
        stockView.turnFaceDown();
        stockView.draw(app.renderer);
        drawDeckCountBadge(app.renderer, deckRect(), static_cast<int>(app.game.deck.size()));
    }

    for (int player = 1; player < app.game.playerCount; ++player) {
        const std::size_t visibleCount = app.dealing ? app.dealtCount[player] : app.game.hand[player].size();
        auto rects = opponentHandLayout(app.game, player);
        for (std::size_t i = 0; i < visibleCount && i < rects.size(); ++i) {
            CardView view;
            view.rect = rects[i];
            view.turnFaceDown();
            view.draw(app.renderer);
        }
    }

    if (!app.collectingTrick) {
        for (std::size_t i = 0; i < app.game.trick.size(); ++i) {
            SDL_FRect rect = trickSlotRect(i, app.game.playerCount);
            const bool winningCard = app.compareDelay >= 0.0f && app.game.trickOwner[i] == app.compareWinner;
            if (winningCard) {
                drawRotatingWinLight(app.renderer, rect, app.time);
            }
            SDL_Texture* compareTexture = loadTexture(app.renderer, cardTexturePath(app.game.trick[i].id));
            if (compareTexture) {
                if (isLocalTeam(app.game.trickOwner[i])) {
                    drawTextureMaterialOutline(app.renderer, compareTexture, rect, 3.4f, 53, 151, 255, 190);
                } else {
                    drawTextureMaterialOutline(app.renderer, compareTexture, rect, 3.4f, 222, 67, 67, 190);
                }
            }
            CardView view;
            view.rect = rect;
            view.setCard(app.game.trick[i].id);
            view.showCard();
            view.updateStateCanPlay(true);
            view.draw(app.renderer);
            if (!compareTexture) {
                if (isLocalTeam(app.game.trickOwner[i])) {
                    strokeRect(app.renderer, rect, 53, 151, 255);
                    strokeRect(app.renderer, SDL_FRect{rect.x + 2.0f, rect.y + 2.0f, rect.w - 4.0f, rect.h - 4.0f}, 53, 151, 255);
                } else {
                    strokeRect(app.renderer, rect, 222, 67, 67);
                    strokeRect(app.renderer, SDL_FRect{rect.x + 2.0f, rect.y + 2.0f, rect.w - 4.0f, rect.h - 4.0f}, 222, 67, 67);
                }
            }
        }
    } else {
        for (const TrickCollectFlight& flight : app.trickCollectFlights) {
            CardView view;
            view.rect = lerpRect(flight.from, flight.to, std::clamp(flight.elapsed / flight.duration, 0.0f, 1.0f));
            view.setCard(flight.card.id);
            view.turnFaceDown();
            view.updateStateCanPlay(true);
            view.draw(app.renderer);
        }
    }

    app.playerHits.clear();
    const std::size_t myVisibleCount = app.dealing ? app.dealtCount[0] : app.game.hand[0].size();
    auto playerRects = twoRowHandLayout(app.game.hand[0].size(), 612.0f, kBaseWidth);
    for (std::size_t i = 0; i < myVisibleCount && i < app.game.hand[0].size(); ++i) {
        const bool playable = !app.dealing && canPlay(app.game, 0, app.game.hand[0][i]);
        const bool shouldDimCard = !app.dealing && app.game.turn == 0 && !playable;
        CardView view;
        view.rect = playerRects[i];
        view.setCard(app.game.hand[0][i].id);
        view.showCard();
        view.updateStateCanPlay(!shouldDimCard);
        view.draw(app.renderer);
        app.playerHits.push_back(CardHit{playerRects[i], i});
    }

    for (const CardFlight& flight : app.flights) {
        CardView view;
        view.rect = lerpRect(flight.from, flight.to, flight.elapsed / flight.duration);
        view.setCard(flight.card.id);
        view.showCard();
        view.updateStateCanPlay(true);
        view.draw(app.renderer);
    }

    for (const DealFlight& flight : app.dealFlights) {
        if (flight.done || flight.elapsed < flight.delay) {
            continue;
        }
        const float t = (flight.elapsed - flight.delay) / flight.duration;
        CardView view;
        view.rect = lerpRect(flight.from, flight.to, t);
        view.setCard(flight.card.id);
        view.turnFaceDown();
        view.draw(app.renderer);
    }

    for (const DrawFlight& flight : app.drawFlights) {
        if (flight.done || flight.elapsed < flight.delay) {
            continue;
        }
        const float t = std::clamp((flight.elapsed - flight.delay) / flight.duration, 0.0f, 1.0f);
        CardView view;
        bool faceUp = false;
        float flipX = 1.0f;
        if (t < 0.22f) {
            view.rect = lerpRect(flight.from, flight.reveal, t / 0.22f);
            flipX = flipScale(t / 0.22f);
            faceUp = t >= 0.11f;
        } else if (t < 0.62f) {
            view.rect = flight.reveal;
            faceUp = true;
        } else {
            view.rect = lerpRect(flight.reveal, flight.to, (t - 0.62f) / 0.38f);
            if (flight.player == 1 && t < 0.82f) {
                flipX = flipScale((t - 0.62f) / 0.20f);
                faceUp = t < 0.72f;
            } else {
                faceUp = flight.player == 0;
            }
        }
        view.setCard(flight.card.id);
        view.updateStateCanPlay(true);
        view.flipScaleX = flipX;
        if (faceUp) {
            view.showCard();
        } else {
            view.turnFaceDown();
        }
        view.draw(app.renderer);
    }

    setColor(app.renderer, 240, 240, 225);
    uiText(app.renderer, 18, 586, "Your hand");

    for (const ScorePopup& popup : app.scorePopups) {
        const float t = std::clamp(popup.elapsed / popup.duration, 0.0f, 1.0f);
        const float eased = 1.0f - std::pow(1.0f - t, 3.0f);
        SDL_FRect rect = lerpRect(popup.from, popup.to, eased);
        rect.y -= (1.0f - t) * 12.0f;
        const bool localTeam = isLocalTeam(popup.player);
        const std::uint8_t alpha = static_cast<std::uint8_t>(230.0f * (1.0f - t * 0.25f));
        fillRect(app.renderer, rect, localTeam ? 43 : 168, localTeam ? 132 : 62, localTeam ? 214 : 59, alpha);
        strokeRect(app.renderer, rect, 247, 234, 183, alpha);
        setColor(app.renderer, 255, 248, 226, alpha);
        uiText(app.renderer, rect.x + (rect.w - uiTextWidth(popup.text)) * 0.5f, rect.y + 6.0f, popup.text);
    }

    if (app.menuOpen) {
        drawMenuOverlay(app);
    }

    if (app.matchOver) {
        drawMatchOverOverlay(app);
        if (app.matchWinnerTeam == 0) {
            drawFireworks(app);
        } else if (app.matchWinnerTeam == 1) {
            drawRainEffect(app);
        }
    }

    SDL_RenderPresent(app.renderer);
}

void handlePointerDown(App& app, float x, float y) {
    if (app.matchOver) {
        if (pointInRect(x, y, app.matchNewGameRect)) {
            playSound(app, SoundEffect::UiTap);
            newDeal(app, app.game.playerCount, false);
            return;
        }
        if (pointInRect(x, y, app.matchLobbyRect)) {
            playSound(app, SoundEffect::UiTap);
            app.exitAction = TressetteExitAction::BackToLobby;
            app.running = false;
            return;
        }
        return;
    }

    if (app.menuOpen) {
        if (pointInRect(x, y, app.menuCloseRect)) {
            playSound(app, SoundEffect::UiTap);
            app.menuOpen = false;
            app.modePickerOpen = false;
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
        if (pointInRect(x, y, app.exitRect)) {
            playSound(app, SoundEffect::UiTap);
            app.exitAction = TressetteExitAction::BackToLobby;
            app.running = false;
            return;
        }
        if (app.modePickerOpen) {
            if (pointInRect(x, y, app.mode1v1Rect)) {
                playSound(app, SoundEffect::UiTap);
                app.menuOpen = false;
                app.modePickerOpen = false;
                newDeal(app, 2);
                return;
            }
            if (pointInRect(x, y, app.mode2v2Rect)) {
                playSound(app, SoundEffect::UiTap);
                app.menuOpen = false;
                app.modePickerOpen = false;
                newDeal(app, 4);
                return;
            }
        } else if (pointInRect(x, y, app.newGameRect)) {
            playSound(app, SoundEffect::UiTap);
            app.modePickerOpen = true;
            return;
        }

        app.menuOpen = false;
        app.modePickerOpen = false;
        return;
    }

    if (pointInRect(x, y, app.menuRect)) {
        playSound(app, SoundEffect::UiTap);
        app.menuOpen = true;
        app.modePickerOpen = false;
        return;
    }
    if (isBusy(app) || app.game.turn != 0 || app.game.roundOver) return;

    for (auto it = app.playerHits.rbegin(); it != app.playerHits.rend(); ++it) {
        if (pointInRect(x, y, it->rect)) {
            startPlayCard(app, 0, it->handIndex, it->rect);
            return;
        }
    }
}

bool init(App& app, const AppWindowState& initialWindowState) {
    SDL_SetAppMetadata("Tressette Offline", "0.1.0", "com.gamestudio.tressette.offline");
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO)) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return false;
    }
    app.window = SDL_CreateWindow("Tressette Offline", kBaseWidth, kBaseHeight, SDL_WINDOW_RESIZABLE);
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
    g_cardAssetRoot = findCardAssetRoot();
    if (g_cardAssetRoot.empty()) {
        SDL_Log("Card asset root not found. Falling back to primitive card rendering.");
    } else {
        SDL_Log("Card asset root: %s", g_cardAssetRoot.string().c_str());
    }
    g_lightAssetRoot = findLightAssetRoot();
    if (g_lightAssetRoot.empty()) {
        SDL_Log("Light asset root not found. Win light effect disabled.");
    } else {
        SDL_Log("Light asset root: %s", g_lightAssetRoot.string().c_str());
    }
    g_avatarAssetRoot = findAvatarAssetRoot();
    if (g_avatarAssetRoot.empty()) {
        SDL_Log("Avatar asset root not found. Falling back to text avatars.");
    } else {
        SDL_Log("Avatar asset root: %s", g_avatarAssetRoot.string().c_str());
    }
    app.audioDevice = SDL_OpenAudioDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, nullptr);
    if (!app.audioDevice) {
        SDL_Log("SDL_OpenAudioDevice failed: %s", SDL_GetError());
    } else {
        SDL_ResumeAudioDevice(app.audioDevice);
    }
    g_soundAssetRoot = findSoundAssetRoot();
    if (g_soundAssetRoot.empty()) {
        SDL_Log("Sound asset root not found. Audio disabled.");
    } else {
        SDL_Log("Sound asset root: %s", g_soundAssetRoot.string().c_str());
    }
    newDeal(app);
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
    for (auto& [_, texture] : g_textureCache) {
        SDL_DestroyTexture(texture);
    }
    g_textureCache.clear();
    if (app.audioDevice) SDL_CloseAudioDevice(app.audioDevice);
    if (app.renderer) SDL_DestroyRenderer(app.renderer);
    if (app.window) SDL_DestroyWindow(app.window);
    SDL_Quit();
}

}  // namespace

TressetteRunResult runTressetteApp(const AppWindowState& initialWindowState) {
    App app;
    if (!init(app, initialWindowState)) {
        shutdown(app);
        return TressetteRunResult{TressetteExitAction::Quit, initialWindowState};
    }

    std::uint64_t lastTicks = SDL_GetTicks();
    while (app.running) {
        const std::uint64_t nowTicks = SDL_GetTicks();
        const float delta = static_cast<float>(nowTicks - lastTicks) / 1000.0f;
        lastTicks = nowTicks;

        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                app.exitAction = TressetteExitAction::Quit;
                app.running = false;
            } else if (event.type == SDL_EVENT_KEY_DOWN) {
                if (event.key.key == SDLK_ESCAPE) {
                    app.exitAction = TressetteExitAction::Quit;
                    app.running = false;
                }
                if (event.key.key == SDLK_N) newDeal(app);
            } else if (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN) {
                if (event.button.which == SDL_TOUCH_MOUSEID) {
                    continue;
                }
                const SDL_FPoint logical = windowToLogical(app.renderer, event.button.x, event.button.y);
                handlePointerDown(app, logical.x, logical.y);
            } else if (event.type == SDL_EVENT_FINGER_DOWN) {
                int outW = 0;
                int outH = 0;
                SDL_GetRenderOutputSize(app.renderer, &outW, &outH);
                const SDL_FPoint logical = windowToLogical(
                    app.renderer,
                    event.tfinger.x * static_cast<float>(outW),
                    event.tfinger.y * static_cast<float>(outH));
                handlePointerDown(app, logical.x, logical.y);
            }
        }

        updateApp(app, delta);
        render(app);
        SDL_Delay(16);
    }

    app.windowState = snapshotWindowState(app.window);
    const TressetteRunResult result{app.exitAction, app.windowState};
    shutdown(app);
    return result;
}
