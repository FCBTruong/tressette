#include "farm_game.h"

#include <SDL3/SDL.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <optional>
#include <random>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

constexpr int kBaseWidth = 480;
constexpr int kBaseHeight = 854;
constexpr int kMaxPlots = 24;
constexpr float kGridTop = 188.0f;
constexpr float kGridLeft = 54.0f;
constexpr float kPlotSize = 82.0f;
constexpr float kPlotGap = 14.0f;
constexpr float kPanelY = 636.0f;
constexpr float kPanelH = 128.0f;
constexpr float kBottomBarY = 778.0f;
constexpr float kBottomButtonH = 46.0f;

enum class PlotState {
    Locked,
    Empty,
    Growing,
    Ready,
};

enum class PanelTab {
    Seeds,
    Orders,
    Storage,
    Upgrade,
};

enum class PressTargetType {
    None,
    Menu,
    Tab,
    Seed,
    Order,
    StorageSell,
    Upgrade,
    PanelClose,
    MenuClose,
    MenuLobby,
};

struct CropDef {
    std::string id;
    std::string name;
    int unlockRank = 1;
    int seedCost = 0;
    int sellPrice = 0;
    double growSeconds = 0.0;
    int baseYield = 1;
    SDL_Color color{255, 255, 255, 255};
};

struct Plot {
    PlotState state = PlotState::Locked;
    std::string cropId;
    double plantedAt = 0.0;
    double growSeconds = 0.0;
    int level = 1;
};

struct OrderItem {
    std::string cropId;
    int amount = 0;
};

struct Order {
    std::vector<OrderItem> items;
    int coinReward = 0;
    int xpReward = 0;
    bool daily = false;
    bool special = false;
};

struct HarvestFly {
    SDL_FPoint start{};
    SDL_FPoint end{};
    SDL_Color color{255, 255, 255, 255};
    float elapsed = 0.0f;
    float duration = 0.65f;
    float size = 8.0f;
};

struct RankRequirement {
    int targetRank = 1;
    int requiredHarvests = 0;
    int requiredOrders = 0;
    int requiredCoinsEarned = 0;
    int requiredGoldenCrops = 0;
    int requiredUnlockedPlots = 0;
    int requiredPlotLevel = 1;
    int requiredPlotLevelCount = 0;
};

struct FarmState {
    int coins = 100;
    int gems = 0;
    int xp = 0;
    int rank = 1;
    int totalCropsHarvested = 0;
    int totalOrdersCompleted = 0;
    int totalCoinsEarned = 0;
    int goldenCropsCollected = 0;
    int dailyStreak = 0;
    long long lastDailyClaimDay = -1;
    std::vector<Plot> plots;
    std::unordered_map<std::string, int> storage;
    std::unordered_map<std::string, int> cropMasteryXp;
    std::vector<Order> orders;
    double lastSaveTime = 0.0;
};

struct App {
    SDL_Window* window = nullptr;
    SDL_Renderer* renderer = nullptr;
    std::mt19937 rng{std::random_device{}()};
    FarmState farm;
    std::vector<SDL_FRect> plotRects;
    std::vector<SDL_FRect> seedRects;
    std::vector<SDL_FRect> orderRects;
    std::vector<std::pair<std::string, SDL_FRect>> storageSellRects;
    std::vector<HarvestFly> harvestFlies;
    SDL_FRect panelRect{};
    SDL_FRect panelCloseRect{};
    SDL_FRect menuRect{};
    SDL_FRect menuLobbyRect{};
    SDL_FRect menuCloseRect{};
    SDL_FRect upgradeButtonRect{};
    std::array<SDL_FRect, 4> tabRects{};
    PanelTab currentTab = PanelTab::Seeds;
    int selectedPlot = -1;
    std::string selectedSeedId = "carrot";
    bool menuOpen = false;
    bool panelOpen = false;
    bool running = true;
    float elapsed = 0.0f;
    float bannerTimer = 0.0f;
    float toastTimer = 0.0f;
    float toastDuration = 0.0f;
    std::string bannerTitle;
    std::string bannerSubtitle;
    std::string status = "Plant your first carrots.";
    std::string toastText;
    SDL_Color toastColor{34, 69, 44, 240};
    SDL_Color toastBorderColor{212, 236, 184, 255};
    PressTargetType pressedTarget = PressTargetType::None;
    int pressedTargetIndex = -1;
    FarmExitAction exitAction = FarmExitAction::Quit;
    AppWindowState windowState{};
};

void layoutBottomTabs(App& app);

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

float easeOutCubic(float t) {
    t = std::clamp(t, 0.0f, 1.0f);
    const float inv = 1.0f - t;
    return 1.0f - inv * inv * inv;
}

float easeInCubic(float t) {
    t = std::clamp(t, 0.0f, 1.0f);
    return t * t * t;
}

float debugTextWidth(const std::string& value) {
    return static_cast<float>(value.size()) * 8.0f;
}

float uiTextWidth(const std::string& value, float scale = 1.0f) {
    return debugTextWidth(value) * scale;
}

void uiText(SDL_Renderer* renderer, float x, float y, const std::string& value, float scale = 1.0f) {
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

double nowSeconds() {
    return std::chrono::duration<double>(std::chrono::system_clock::now().time_since_epoch()).count();
}

long long currentDayIndex() {
    return static_cast<long long>(std::floor(nowSeconds() / 86400.0));
}

std::filesystem::path savePath() {
    return std::filesystem::current_path() / "farm_save.txt";
}

const std::vector<CropDef>& cropDefs() {
    static const std::vector<CropDef> defs{
        {"carrot", "Carrot", 1, 5, 9, 30.0, 1, SDL_Color{242, 142, 44, 255}},
        {"corn", "Corn", 2, 15, 28, 120.0, 1, SDL_Color{255, 211, 79, 255}},
        {"tomato", "Tomato", 3, 35, 75, 300.0, 1, SDL_Color{227, 76, 63, 255}},
        {"potato", "Potato", 4, 60, 135, 600.0, 1, SDL_Color{153, 111, 74, 255}},
        {"strawberry", "Strawberry", 5, 110, 260, 1200.0, 1, SDL_Color{232, 80, 117, 255}},
        {"pumpkin", "Pumpkin", 7, 300, 780, 3600.0, 1, SDL_Color{223, 126, 33, 255}},
        {"golden_wheat", "Golden Wheat", 10, 900, 2600, 10800.0, 1, SDL_Color{240, 204, 93, 255}},
    };
    return defs;
}

const std::vector<RankRequirement>& rankRequirements() {
    static const std::vector<RankRequirement> requirements{
        {2, 20, 3, 200, 0, 12, 1, 0},
        {3, 80, 10, 1000, 0, 14, 2, 3},
        {4, 200, 25, 5000, 1, 16, 3, 5},
        {5, 500, 50, 20000, 10, 20, 3, 10},
    };
    return requirements;
}

const CropDef* findCropDef(const std::string& cropId) {
    const auto& defs = cropDefs();
    auto it = std::find_if(defs.begin(), defs.end(), [&cropId](const CropDef& def) {
        return def.id == cropId;
    });
    return (it == defs.end()) ? nullptr : &(*it);
}

std::string cropShortName(const std::string& cropId) {
    if (const CropDef* def = findCropDef(cropId)) {
        return def->name;
    }
    return cropId;
}

std::string formatDuration(double seconds) {
    const int total = std::max(0, static_cast<int>(std::round(seconds)));
    const int hours = total / 3600;
    const int minutes = (total % 3600) / 60;
    const int secs = total % 60;
    if (hours > 0) {
        return std::to_string(hours) + "h " + std::to_string(minutes) + "m";
    }
    if (minutes > 0) {
        return std::to_string(minutes) + "m " + std::to_string(secs) + "s";
    }
    return std::to_string(secs) + "s";
}

std::string rankName(int rank) {
    if (rank <= 1) return "Tiny Farm";
    if (rank == 2) return "Fresh Farm";
    if (rank == 3) return "Busy Farm";
    if (rank == 4) return "Local Farm";
    if (rank == 5) return "Golden Farm";
    return "Endless Rank " + std::to_string(rank - 5);
}

RankRequirement requirementForNextRank(int currentRank) {
    const int targetRank = currentRank + 1;
    for (const RankRequirement& requirement : rankRequirements()) {
        if (requirement.targetRank == targetRank) {
            return requirement;
        }
    }

    const int endlessStep = std::max(1, targetRank - 5);
    return RankRequirement{
        targetRank,
        500 + endlessStep * 220,
        50 + endlessStep * 15,
        20000 + endlessStep * 9000,
        10 + endlessStep * 4,
        24,
        4,
        std::min(24, 10 + endlessStep * 2),
    };
}

int countUnlockedPlots(const FarmState& farm) {
    int count = 0;
    for (const Plot& plot : farm.plots) {
        if (plot.state != PlotState::Locked) {
            ++count;
        }
    }
    return count;
}

int countPlotsAtLeastLevel(const FarmState& farm, int level) {
    int count = 0;
    for (const Plot& plot : farm.plots) {
        if (plot.state != PlotState::Locked && plot.level >= level) {
            ++count;
        }
    }
    return count;
}

bool canRankUp(const FarmState& farm, const RankRequirement& req) {
    if (farm.totalCropsHarvested < req.requiredHarvests) return false;
    if (farm.totalOrdersCompleted < req.requiredOrders) return false;
    if (farm.totalCoinsEarned < req.requiredCoinsEarned) return false;
    if (farm.goldenCropsCollected < req.requiredGoldenCrops) return false;
    if (countUnlockedPlots(farm) < req.requiredUnlockedPlots) return false;
    if (req.requiredPlotLevelCount > 0 && countPlotsAtLeastLevel(farm, req.requiredPlotLevel) < req.requiredPlotLevelCount) return false;
    return true;
}

float rankProgress(const FarmState& farm) {
    const RankRequirement req = requirementForNextRank(farm.rank);
    std::vector<float> progress;
    progress.push_back(static_cast<float>(farm.totalCropsHarvested) / std::max(1, req.requiredHarvests));
    progress.push_back(static_cast<float>(farm.totalOrdersCompleted) / std::max(1, req.requiredOrders));
    progress.push_back(static_cast<float>(farm.totalCoinsEarned) / std::max(1, req.requiredCoinsEarned));
    if (req.requiredGoldenCrops > 0) {
        progress.push_back(static_cast<float>(farm.goldenCropsCollected) / static_cast<float>(req.requiredGoldenCrops));
    }
    progress.push_back(static_cast<float>(countUnlockedPlots(farm)) / static_cast<float>(std::max(1, req.requiredUnlockedPlots)));
    if (req.requiredPlotLevelCount > 0) {
        progress.push_back(static_cast<float>(countPlotsAtLeastLevel(farm, req.requiredPlotLevel)) / static_cast<float>(req.requiredPlotLevelCount));
    }
    float total = 0.0f;
    for (float value : progress) {
        total += std::clamp(value, 0.0f, 1.0f);
    }
    return progress.empty() ? 0.0f : total / static_cast<float>(progress.size());
}

int plotUpgradeCost(int level) {
    switch (level) {
    case 1: return 100;
    case 2: return 400;
    case 3: return 1200;
    case 4: return 3000;
    default: return 0;
    }
}

int unlockedPlotTargetForRank(int rank) {
    if (rank <= 1) return 12;
    if (rank == 2) return 14;
    if (rank == 3) return 16;
    if (rank == 4) return 20;
    return 24;
}

void unlockPlotsUpTo(FarmState& farm, int unlockedTarget) {
    int unlocked = countUnlockedPlots(farm);
    for (Plot& plot : farm.plots) {
        if (unlocked >= unlockedTarget) {
            break;
        }
        if (plot.state == PlotState::Locked) {
            plot.state = PlotState::Empty;
            plot.level = 1;
            ++unlocked;
        }
    }
}

std::vector<std::size_t> unlockedCropIndices(const FarmState& farm) {
    std::vector<std::size_t> indices;
    const auto& defs = cropDefs();
    for (std::size_t i = 0; i < defs.size(); ++i) {
        if (defs[i].unlockRank <= farm.rank) {
            indices.push_back(i);
        }
    }
    return indices;
}

Order generateOrder(const FarmState& farm, std::mt19937& rng, bool special = false) {
    const auto unlocked = unlockedCropIndices(farm);
    if (unlocked.empty()) {
        return {};
    }

    std::uniform_int_distribution<int> cropDist(0, static_cast<int>(unlocked.size()) - 1);
    const auto& defs = cropDefs();
    Order order;
    order.daily = false;
    order.special = special;
    const int itemCount = special ? 2 : ((farm.rank >= 3 && unlocked.size() > 1) ? ((cropDist(rng) % 2) + 1) : 1);
    int rewardBase = 0;
    for (int i = 0; i < itemCount; ++i) {
        const CropDef& def = defs[unlocked[static_cast<std::size_t>(cropDist(rng))]];
        const int amount = special ? (2 + farm.rank + i) : std::max(2, 1 + farm.rank + (cropDist(rng) % 3));
        auto existing = std::find_if(order.items.begin(), order.items.end(), [&def](const OrderItem& item) {
            return item.cropId == def.id;
        });
        if (existing != order.items.end()) {
            existing->amount += amount;
        } else {
            order.items.push_back(OrderItem{def.id, amount});
        }
        rewardBase += def.sellPrice * amount;
    }
    order.coinReward = static_cast<int>(std::round(rewardBase * (special ? 2.0 : 1.55))) + farm.rank * 18;
    order.xpReward = order.coinReward / 6;
    return order;
}

void refillOrders(FarmState& farm, std::mt19937& rng) {
    while (farm.orders.size() < 3) {
        const bool special = farm.rank >= 4 && farm.orders.empty();
        farm.orders.push_back(generateOrder(farm, rng, special));
    }
}

bool canCompleteOrder(const FarmState& farm, const Order& order) {
    for (const OrderItem& item : order.items) {
        auto it = farm.storage.find(item.cropId);
        if (it == farm.storage.end() || it->second < item.amount) {
            return false;
        }
    }
    return true;
}

bool completeOrder(FarmState& farm, const Order& order) {
    if (!canCompleteOrder(farm, order)) {
        return false;
    }
    for (const OrderItem& item : order.items) {
        farm.storage[item.cropId] -= item.amount;
    }
    farm.coins += order.coinReward;
    farm.xp += order.xpReward;
    farm.totalCoinsEarned += order.coinReward;
    farm.totalOrdersCompleted += 1;
    return true;
}

void updateFarmGrowth(FarmState& farm, double now) {
    for (Plot& plot : farm.plots) {
        if (plot.state != PlotState::Growing) {
            continue;
        }
        if (now - plot.plantedAt >= plot.growSeconds) {
            plot.state = PlotState::Ready;
        }
    }
}

bool plantCrop(FarmState& farm, int plotIndex, const CropDef& crop, double now) {
    if (plotIndex < 0 || plotIndex >= static_cast<int>(farm.plots.size())) {
        return false;
    }
    Plot& plot = farm.plots[static_cast<std::size_t>(plotIndex)];
    if (plot.state != PlotState::Empty || farm.coins < crop.seedCost) {
        return false;
    }
    farm.coins -= crop.seedCost;
    plot.state = PlotState::Growing;
    plot.cropId = crop.id;
    plot.plantedAt = now;
    double speedMultiplier = 1.0;
    if (plot.level >= 2) speedMultiplier -= 0.05;
    if (plot.level >= 3) speedMultiplier -= 0.05;
    if (plot.level >= 4) speedMultiplier -= 0.05;
    if (plot.level >= 5) speedMultiplier -= 0.05;
    plot.growSeconds = crop.growSeconds * speedMultiplier;
    return true;
}

bool harvestPlot(FarmState& farm, int plotIndex, std::mt19937& rng, std::string& resultLabel) {
    if (plotIndex < 0 || plotIndex >= static_cast<int>(farm.plots.size())) {
        return false;
    }
    Plot& plot = farm.plots[static_cast<std::size_t>(plotIndex)];
    if (plot.state != PlotState::Ready) {
        return false;
    }
    const CropDef* crop = findCropDef(plot.cropId);
    if (!crop) {
        return false;
    }
    int yield = crop->baseYield;
    if (plot.level >= 3) {
        std::uniform_real_distribution<float> dist(0.0f, 1.0f);
        if (dist(rng) < 0.15f) {
            yield += 1;
        }
    }
    bool golden = false;
    {
        std::uniform_real_distribution<float> dist(0.0f, 1.0f);
        float chance = 0.02f;
        if (plot.level >= 4) chance += 0.01f;
        if (plot.level >= 5) chance += 0.02f;
        if (dist(rng) < chance) {
            golden = true;
        }
    }
    farm.storage[crop->id] += yield;
    farm.totalCropsHarvested += yield;
    farm.cropMasteryXp[crop->id] += yield;
    farm.xp += 8 + yield * 3;
    if (golden) {
        farm.storage["golden_" + crop->id] += 1;
        farm.goldenCropsCollected += 1;
        resultLabel = "+" + std::to_string(yield) + " " + crop->name + " + Golden!";
    } else {
        resultLabel = "+" + std::to_string(yield) + " " + crop->name;
    }
    plot.state = PlotState::Empty;
    plot.cropId.clear();
    plot.plantedAt = 0.0;
    plot.growSeconds = 0.0;
    return true;
}

void saveFarm(const FarmState& farm) {
    std::ofstream out(savePath(), std::ios::trunc);
    if (!out) {
        return;
    }
    out << "TINY_GOLDEN_FARM_V1\n";
    out << farm.coins << ' ' << farm.gems << ' ' << farm.xp << ' ' << farm.rank << ' '
        << farm.totalCropsHarvested << ' ' << farm.totalOrdersCompleted << ' ' << farm.totalCoinsEarned << ' '
        << farm.goldenCropsCollected << ' ' << farm.dailyStreak << ' ' << farm.lastDailyClaimDay << ' ' << farm.lastSaveTime << "\n";
    out << farm.plots.size() << "\n";
    for (const Plot& plot : farm.plots) {
        out << static_cast<int>(plot.state) << ' ' << plot.level << ' ' << (plot.cropId.empty() ? "-" : plot.cropId) << ' '
            << plot.plantedAt << ' ' << plot.growSeconds << "\n";
    }
    out << farm.storage.size() << "\n";
    for (const auto& [cropId, amount] : farm.storage) {
        out << cropId << ' ' << amount << "\n";
    }
    out << farm.cropMasteryXp.size() << "\n";
    for (const auto& [cropId, amount] : farm.cropMasteryXp) {
        out << cropId << ' ' << amount << "\n";
    }
}

FarmState makeDefaultFarm() {
    FarmState farm;
    farm.plots.resize(kMaxPlots);
    unlockPlotsUpTo(farm, 12);
    return farm;
}

std::optional<FarmState> loadFarm() {
    std::ifstream in(savePath());
    if (!in) {
        return std::nullopt;
    }
    std::string magic;
    in >> magic;
    if (magic != "TINY_GOLDEN_FARM_V1") {
        return std::nullopt;
    }
    FarmState farm;
    in >> farm.coins >> farm.gems >> farm.xp >> farm.rank >> farm.totalCropsHarvested >> farm.totalOrdersCompleted >> farm.totalCoinsEarned
       >> farm.goldenCropsCollected >> farm.dailyStreak >> farm.lastDailyClaimDay >> farm.lastSaveTime;
    std::size_t plotCount = 0;
    in >> plotCount;
    farm.plots.resize(plotCount);
    for (std::size_t i = 0; i < plotCount; ++i) {
        int state = 0;
        std::string cropId;
        in >> state >> farm.plots[i].level >> cropId >> farm.plots[i].plantedAt >> farm.plots[i].growSeconds;
        farm.plots[i].state = static_cast<PlotState>(state);
        farm.plots[i].cropId = (cropId == "-") ? "" : cropId;
    }
    std::size_t storageCount = 0;
    in >> storageCount;
    for (std::size_t i = 0; i < storageCount; ++i) {
        std::string cropId;
        int amount = 0;
        in >> cropId >> amount;
        farm.storage[cropId] = amount;
    }
    std::size_t masteryCount = 0;
    in >> masteryCount;
    for (std::size_t i = 0; i < masteryCount; ++i) {
        std::string cropId;
        int amount = 0;
        in >> cropId >> amount;
        farm.cropMasteryXp[cropId] = amount;
    }
    if (farm.plots.size() < kMaxPlots) {
        farm.plots.resize(kMaxPlots);
    }
    return farm;
}

void showBanner(App& app, std::string title, std::string subtitle, float duration) {
    app.bannerTitle = std::move(title);
    app.bannerSubtitle = std::move(subtitle);
    app.bannerTimer = std::max(app.bannerTimer, duration);
}

void maybeRankUp(App& app) {
    while (canRankUp(app.farm, requirementForNextRank(app.farm.rank))) {
        ++app.farm.rank;
        unlockPlotsUpTo(app.farm, unlockedPlotTargetForRank(app.farm.rank));
        app.farm.coins += 120 * app.farm.rank;
        showBanner(app, "Rank Up!", rankName(app.farm.rank), 1.8f);
        app.status = "New crops and plots unlocked.";
        refillOrders(app.farm, app.rng);
    }
}

void applyDailyReward(App& app) {
    const long long today = currentDayIndex();
    if (app.farm.lastDailyClaimDay == today) {
        return;
    }
    if (app.farm.lastDailyClaimDay == today - 1) {
        app.farm.dailyStreak += 1;
    } else {
        app.farm.dailyStreak = 1;
    }
    app.farm.lastDailyClaimDay = today;
    const int streak = ((app.farm.dailyStreak - 1) % 7) + 1;
    int rewardCoins = 0;
    if (streak == 1) rewardCoins = 100;
    else if (streak == 2) rewardCoins = 150;
    else if (streak == 3) rewardCoins = 220;
    else if (streak == 4) rewardCoins = 300;
    else if (streak == 5) rewardCoins = 420;
    else if (streak == 6) rewardCoins = 560;
    else rewardCoins = 800;
    app.farm.coins += rewardCoins;
    app.farm.totalCoinsEarned += rewardCoins;
    showBanner(app, "Daily Reward", "+" + std::to_string(rewardCoins) + " coins", 1.8f);
}

void loadOrResetFarm(App& app) {
    const double now = nowSeconds();
    if (const std::optional<FarmState> loaded = loadFarm()) {
        app.farm = *loaded;
        if (app.farm.plots.size() < kMaxPlots) {
            app.farm.plots.resize(kMaxPlots);
        }
        const int beforeReady = static_cast<int>(std::count_if(app.farm.plots.begin(), app.farm.plots.end(), [](const Plot& plot) {
            return plot.state == PlotState::Ready;
        }));
        updateFarmGrowth(app.farm, now);
        const int afterReady = static_cast<int>(std::count_if(app.farm.plots.begin(), app.farm.plots.end(), [](const Plot& plot) {
            return plot.state == PlotState::Ready;
        }));
        refillOrders(app.farm, app.rng);
        if (afterReady > beforeReady) {
            showBanner(app, "Welcome back", std::to_string(afterReady) + " crops are ready.", 2.0f);
        }
    } else {
        app.farm = makeDefaultFarm();
        refillOrders(app.farm, app.rng);
    }
    applyDailyReward(app);
    maybeRankUp(app);
    app.farm.lastSaveTime = now;
    saveFarm(app.farm);
}

std::vector<SDL_FRect> makePlotRects() {
    std::vector<SDL_FRect> rects;
    rects.reserve(kMaxPlots);
    for (int i = 0; i < kMaxPlots; ++i) {
        const int row = i / 4;
        const int col = i % 4;
        rects.push_back(SDL_FRect{
            kGridLeft + static_cast<float>(col) * (kPlotSize + kPlotGap),
            kGridTop + static_cast<float>(row) * (kPlotSize + kPlotGap),
            kPlotSize,
            kPlotSize,
        });
    }
    return rects;
}

std::string orderLabel(const Order& order) {
    std::string label;
    for (std::size_t i = 0; i < order.items.size(); ++i) {
        if (i > 0) label += " + ";
        label += std::to_string(order.items[i].amount) + " " + cropShortName(order.items[i].cropId);
    }
    return label;
}

void clearPressedTarget(App& app) {
    app.pressedTarget = PressTargetType::None;
    app.pressedTargetIndex = -1;
}

bool isPressed(const App& app, PressTargetType type, int index = -1) {
    return app.pressedTarget == type && app.pressedTargetIndex == index;
}

void showToast(App& app, const std::string& text, bool error = false, float duration = 1.8f) {
    app.status = text;
    app.toastText = text;
    app.toastDuration = duration;
    app.toastTimer = duration;
    if (error) {
        app.toastColor = SDL_Color{104, 42, 36, 240};
        app.toastBorderColor = SDL_Color{246, 179, 156, 255};
    } else {
        app.toastColor = SDL_Color{34, 69, 44, 240};
        app.toastBorderColor = SDL_Color{212, 236, 184, 255};
    }
}

SDL_FRect scaledRect(SDL_FRect rect, float scale) {
    const float scaledW = rect.w * scale;
    const float scaledH = rect.h * scale;
    rect.x += (rect.w - scaledW) * 0.5f;
    rect.y += (rect.h - scaledH) * 0.5f;
    rect.w = scaledW;
    rect.h = scaledH;
    return rect;
}

SDL_FPoint rectCenter(const SDL_FRect& rect) {
    return SDL_FPoint{rect.x + rect.w * 0.5f, rect.y + rect.h * 0.5f};
}

void spawnHarvestFly(App& app, int plotIndex, const SDL_Color& color, int amount) {
    if (plotIndex < 0 || plotIndex >= static_cast<int>(app.plotRects.size())) {
        return;
    }
    if (app.tabRects[2].w <= 0.0f || app.tabRects[2].h <= 0.0f) {
        layoutBottomTabs(app);
    }
    const SDL_FPoint start = rectCenter(app.plotRects[static_cast<std::size_t>(plotIndex)]);
    const SDL_FPoint end = rectCenter(app.tabRects[2]);
    const int burstCount = std::clamp(amount, 2, 4);
    for (int i = 0; i < burstCount; ++i) {
        HarvestFly fly;
        fly.start = SDL_FPoint{start.x + static_cast<float>(i - 1) * 8.0f, start.y - static_cast<float>(i % 2) * 6.0f};
        fly.end = SDL_FPoint{end.x + static_cast<float>(i - 1) * 4.0f, end.y};
        fly.color = color;
        fly.duration = 0.52f + static_cast<float>(i) * 0.06f;
        fly.size = 7.0f + static_cast<float>(i % 2) * 2.0f;
        app.harvestFlies.push_back(fly);
    }
}

void drawButton(SDL_Renderer* renderer, const SDL_FRect& rect, const std::string& label,
                std::uint8_t r, std::uint8_t g, std::uint8_t b, float scale = 1.0f, bool pressed = false) {
    const SDL_FRect drawRect = pressed ? scaledRect(rect, 0.94f) : rect;
    fillRect(renderer, drawRect, r, g, b, 236);
    strokeRect(renderer, drawRect, 44, 37, 28, 255);
    setColor(renderer, 28, 25, 22, 255);
    uiText(renderer, drawRect.x + drawRect.w * 0.5f - uiTextWidth(label, scale) * 0.5f, drawRect.y + 12.0f, label, scale);
}

void drawTopBar(App& app) {
    fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, 138.0f}, 36, 89, 62, 255);
    fillRect(app.renderer, SDL_FRect{16.0f, 18.0f, kBaseWidth - 32.0f, 104.0f}, 18, 48, 35, 132);
    strokeRect(app.renderer, SDL_FRect{16.0f, 18.0f, kBaseWidth - 32.0f, 104.0f}, 236, 222, 174, 96);

    setColor(app.renderer, 250, 242, 216, 255);
    uiText(app.renderer, 20.0f, 18.0f, "Tiny Golden Farm", 1.42f);
    uiText(app.renderer, 20.0f, 50.0f, "Coins " + std::to_string(app.farm.coins), 1.04f);
    uiText(app.renderer, 20.0f, 74.0f, rankName(app.farm.rank), 1.0f);

    app.menuRect = SDL_FRect{kBaseWidth - 100.0f, 24.0f, 80.0f, 34.0f};
    drawButton(app.renderer, app.menuRect, "Menu", 232, 191, 92, 0.95f, isPressed(app, PressTargetType::Menu));

    const SDL_FRect progressBox{170.0f, 72.0f, 290.0f, 18.0f};
    fillRect(app.renderer, progressBox, 11, 26, 18, 170);
    strokeRect(app.renderer, progressBox, 234, 220, 174, 120);
    const float progress = rankProgress(app.farm);
    fillRect(app.renderer, SDL_FRect{progressBox.x + 2.0f, progressBox.y + 2.0f, (progressBox.w - 4.0f) * progress, progressBox.h - 4.0f}, 246, 197, 86, 255);
    setColor(app.renderer, 245, 241, 220, 255);
    uiText(app.renderer, 170.0f, 48.0f, "Farm Rank " + std::to_string(app.farm.rank), 1.0f);
    uiText(app.renderer, progressBox.x + progressBox.w * 0.5f - uiTextWidth("Progress", 0.86f) * 0.5f, progressBox.y + 3.0f, "Progress", 0.86f);
}

void drawBackground(App& app) {
    fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 101, 178, 114, 255);
    fillRect(app.renderer, SDL_FRect{0, 138.0f, kBaseWidth, 530.0f}, 127, 194, 112, 255);
    fillRect(app.renderer, SDL_FRect{0, 668.0f, kBaseWidth, 186.0f}, 82, 133, 88, 255);
    for (int i = 0; i < 16; ++i) {
        const float x = static_cast<float>(i) * 34.0f;
        setColor(app.renderer, 255, 255, 255, 10);
        SDL_RenderLine(app.renderer, x, 138.0f, x + 120.0f, 668.0f);
    }
}

void drawPlot(App& app, int index) {
    const SDL_FRect rect = app.plotRects[static_cast<std::size_t>(index)];
    const Plot& plot = app.farm.plots[static_cast<std::size_t>(index)];
    const bool selected = index == app.selectedPlot;

    if (plot.state == PlotState::Locked) {
        fillRect(app.renderer, rect, 53, 76, 52, 220);
        strokeRect(app.renderer, rect, 118, 132, 112, 190);
        setColor(app.renderer, 212, 216, 196, 255);
        uiText(app.renderer, rect.x + rect.w * 0.5f - uiTextWidth("Locked", 0.82f) * 0.5f, rect.y + 30.0f, "Locked", 0.82f);
        return;
    }

    fillRect(app.renderer, rect, 119, 81, 51, 255);
    fillRect(app.renderer, SDL_FRect{rect.x + 5.0f, rect.y + 5.0f, rect.w - 10.0f, rect.h - 10.0f}, 140, 98, 62, 255);
    strokeRect(app.renderer, rect, selected ? 255 : 75, selected ? 224 : 53, selected ? 121 : 37, 255);

    if (plot.state == PlotState::Empty) {
        setColor(app.renderer, 246, 231, 185, 255);
        uiText(app.renderer, rect.x + 10.0f, rect.y + 12.0f, "Lv." + std::to_string(plot.level), 0.82f);
        uiText(app.renderer, rect.x + rect.w * 0.5f - uiTextWidth("Plant", 0.94f) * 0.5f, rect.y + 34.0f, "Plant", 0.94f);
        return;
    }

    const CropDef* crop = findCropDef(plot.cropId);
    if (!crop) {
        return;
    }

    fillRect(app.renderer, SDL_FRect{rect.x + 8.0f, rect.y + 8.0f, rect.w - 16.0f, rect.h - 16.0f}, crop->color.r, crop->color.g, crop->color.b, 150);
    setColor(app.renderer, 252, 247, 222, 255);
    uiText(app.renderer, rect.x + 8.0f, rect.y + 8.0f, crop->name, 0.74f);
    uiText(app.renderer, rect.x + 8.0f, rect.y + 24.0f, "Lv." + std::to_string(plot.level), 0.74f);

    if (plot.state == PlotState::Growing) {
        const double remaining = std::max(0.0, plot.growSeconds - (nowSeconds() - plot.plantedAt));
        uiText(app.renderer, rect.x + rect.w * 0.5f - uiTextWidth(formatDuration(remaining), 0.8f) * 0.5f, rect.y + 48.0f, formatDuration(remaining), 0.8f);
        fillCircle(app.renderer, rect.x + rect.w * 0.5f, rect.y + rect.h - 20.0f, 10.0f, 88, 199, 94, 255);
        fillCircle(app.renderer, rect.x + rect.w * 0.5f - 7.0f, rect.y + rect.h - 24.0f, 6.0f, 122, 221, 114, 240);
        fillCircle(app.renderer, rect.x + rect.w * 0.5f + 7.0f, rect.y + rect.h - 24.0f, 6.0f, 122, 221, 114, 240);
    } else if (plot.state == PlotState::Ready) {
        uiText(app.renderer, rect.x + rect.w * 0.5f - uiTextWidth("Ready", 0.92f) * 0.5f, rect.y + 46.0f, "Ready", 0.92f);
        fillCircle(app.renderer, rect.x + rect.w * 0.5f, rect.y + rect.h - 22.0f, 14.0f, crop->color.r, crop->color.g, crop->color.b, 255);
        fillCircle(app.renderer, rect.x + rect.w * 0.5f, rect.y + rect.h - 22.0f, 6.0f, 255, 245, 215, 220);
    }
}

void drawGrid(App& app) {
    for (int i = 0; i < static_cast<int>(app.plotRects.size()); ++i) {
        drawPlot(app, i);
    }
}

void layoutBottomTabs(App& app) {
    const float width = 104.0f;
    const float gap = 10.0f;
    const float startX = 18.0f;
    for (int i = 0; i < 4; ++i) {
        app.tabRects[static_cast<std::size_t>(i)] = SDL_FRect{startX + static_cast<float>(i) * (width + gap), kBottomBarY, width, kBottomButtonH};
    }
}

void drawBottomTabs(App& app) {
    layoutBottomTabs(app);
    const std::array<std::string, 4> labels{"Seeds", "Orders", "Storage", "Upgrade"};
    for (int i = 0; i < 4; ++i) {
        const bool active = app.panelOpen && static_cast<int>(app.currentTab) == i;
        drawButton(app.renderer, app.tabRects[static_cast<std::size_t>(i)], labels[static_cast<std::size_t>(i)], active ? 244 : 205, active ? 192 : 170, active ? 92 : 118, 0.9f, isPressed(app, PressTargetType::Tab, i));
    }
}

void drawSeedsPanel(App& app) {
    app.seedRects.clear();
    const auto unlocked = unlockedCropIndices(app.farm);
    const float itemW = 138.0f;
    const float itemH = 44.0f;
    const float gap = 10.0f;
    for (std::size_t i = 0; i < unlocked.size(); ++i) {
        const CropDef& crop = cropDefs()[unlocked[i]];
        const int row = static_cast<int>(i) / 3;
        const int col = static_cast<int>(i) % 3;
        SDL_FRect rect{app.panelRect.x + 16.0f + static_cast<float>(col) * (itemW + gap), app.panelRect.y + 44.0f + static_cast<float>(row) * (itemH + 8.0f), itemW, itemH};
        app.seedRects.push_back(rect);
        const bool active = app.selectedSeedId == crop.id;
        drawButton(app.renderer, rect, crop.name, active ? crop.color.r : 220, active ? crop.color.g : 200, active ? crop.color.b : 164, 0.86f, isPressed(app, PressTargetType::Seed, static_cast<int>(i)));
        setColor(app.renderer, 36, 28, 20, 255);
        uiText(app.renderer, rect.x + 8.0f, rect.y + 26.0f, std::to_string(crop.seedCost) + "c", 0.72f);
        uiText(app.renderer, rect.x + rect.w - uiTextWidth(formatDuration(crop.growSeconds), 0.72f) - 8.0f, rect.y + 26.0f, formatDuration(crop.growSeconds), 0.72f);
    }
}

void drawOrdersPanel(App& app) {
    app.orderRects.clear();
    for (std::size_t i = 0; i < app.farm.orders.size(); ++i) {
        SDL_FRect rect{app.panelRect.x + 16.0f, app.panelRect.y + 42.0f + static_cast<float>(i) * 38.0f, 428.0f, 34.0f};
        app.orderRects.push_back(rect);
        const bool canDo = canCompleteOrder(app.farm, app.farm.orders[i]);
        const SDL_FRect drawRect = isPressed(app, PressTargetType::Order, static_cast<int>(i)) ? scaledRect(rect, 0.97f) : rect;
        fillRect(app.renderer, drawRect, canDo ? 94 : 55, canDo ? 128 : 73, canDo ? 84 : 66, 228);
        strokeRect(app.renderer, drawRect, 238, 224, 178, 120);
        setColor(app.renderer, 246, 241, 214, 255);
        uiText(app.renderer, drawRect.x + 8.0f, drawRect.y + 8.0f, orderLabel(app.farm.orders[i]), 0.76f);
        const std::string reward = "+" + std::to_string(app.farm.orders[i].coinReward) + "c";
        uiText(app.renderer, drawRect.x + drawRect.w - uiTextWidth(reward, 0.76f) - 10.0f, drawRect.y + 8.0f, reward, 0.76f);
    }
}

void drawStoragePanel(App& app) {
    app.storageSellRects.clear();
    const auto unlocked = unlockedCropIndices(app.farm);
    float y = app.panelRect.y + 42.0f;
    for (std::size_t i = 0; i < unlocked.size(); ++i) {
        const CropDef& crop = cropDefs()[unlocked[i]];
        const int amount = app.farm.storage[crop.id];
        SDL_FRect row{app.panelRect.x + 16.0f, y, 428.0f, 32.0f};
        fillRect(app.renderer, row, 34, 52, 39, 190);
        strokeRect(app.renderer, row, 226, 214, 176, 90);
        setColor(app.renderer, 244, 240, 214, 255);
        uiText(app.renderer, row.x + 8.0f, row.y + 7.0f, crop.name + " x" + std::to_string(amount), 0.8f);
        SDL_FRect sellRect{row.x + row.w - 82.0f, row.y + 3.0f, 72.0f, 26.0f};
        app.storageSellRects.push_back({crop.id, sellRect});
        drawButton(app.renderer, sellRect, "Sell", 233, 191, 94, 0.7f, isPressed(app, PressTargetType::StorageSell, static_cast<int>(i)));
        y += 36.0f;
        if (y > app.panelRect.y + app.panelRect.h - 36.0f) {
            break;
        }
    }
}

void drawUpgradePanel(App& app) {
    const SDL_FRect infoRect{app.panelRect.x + 16.0f, app.panelRect.y + 44.0f, 428.0f, 84.0f};
    fillRect(app.renderer, infoRect, 33, 51, 38, 208);
    strokeRect(app.renderer, infoRect, 238, 224, 178, 110);
    setColor(app.renderer, 247, 241, 212, 255);
    if (app.selectedPlot < 0 || app.selectedPlot >= static_cast<int>(app.farm.plots.size()) || app.farm.plots[static_cast<std::size_t>(app.selectedPlot)].state == PlotState::Locked) {
        uiText(app.renderer, infoRect.x + 14.0f, infoRect.y + 18.0f, "Select an unlocked plot to upgrade.", 0.9f);
        app.upgradeButtonRect = SDL_FRect{};
        return;
    }

    const Plot& plot = app.farm.plots[static_cast<std::size_t>(app.selectedPlot)];
    uiText(app.renderer, infoRect.x + 12.0f, infoRect.y + 10.0f, "Plot #" + std::to_string(app.selectedPlot + 1), 0.96f);
    uiText(app.renderer, infoRect.x + 12.0f, infoRect.y + 34.0f, "Level " + std::to_string(plot.level), 0.86f);
    uiText(app.renderer, infoRect.x + 12.0f, infoRect.y + 56.0f, plot.level < 5 ? ("Next cost " + std::to_string(plotUpgradeCost(plot.level)) + "c") : "Max level reached", 0.82f);
    app.upgradeButtonRect = SDL_FRect{infoRect.x + infoRect.w - 120.0f, infoRect.y + 24.0f, 104.0f, 36.0f};
    if (plot.level < 5) {
        drawButton(app.renderer, app.upgradeButtonRect, "Upgrade", 228, 194, 94, 0.82f, isPressed(app, PressTargetType::Upgrade));
    } else {
        drawButton(app.renderer, app.upgradeButtonRect, "Max", 126, 148, 114, 0.82f, isPressed(app, PressTargetType::Upgrade));
    }
}

float panelHeightForTab(const App& app) {
    switch (app.currentTab) {
    case PanelTab::Seeds: {
        const int rows = std::max(1, static_cast<int>((unlockedCropIndices(app.farm).size() + 2) / 3));
        return std::min(206.0f, 54.0f + static_cast<float>(rows) * 52.0f + 18.0f);
    }
    case PanelTab::Orders:
        return std::min(190.0f, 54.0f + static_cast<float>(app.farm.orders.size()) * 38.0f + 14.0f);
    case PanelTab::Storage:
        return 186.0f;
    case PanelTab::Upgrade:
        return 144.0f;
    }
    return 160.0f;
}

std::string panelTitle(PanelTab tab) {
    switch (tab) {
    case PanelTab::Seeds: return "Seeds";
    case PanelTab::Orders: return "Orders";
    case PanelTab::Storage: return "Storage";
    case PanelTab::Upgrade: return "Upgrade";
    }
    return "Panel";
}

void drawPanel(App& app) {
    app.seedRects.clear();
    app.orderRects.clear();
    app.storageSellRects.clear();
    app.upgradeButtonRect = SDL_FRect{};
    app.panelRect = SDL_FRect{};
    app.panelCloseRect = SDL_FRect{};
    if (!app.panelOpen) {
        return;
    }

    const float panelH = panelHeightForTab(app);
    app.panelRect = SDL_FRect{10.0f, kBottomBarY - panelH - 12.0f, 460.0f, panelH};
    fillRect(app.renderer, app.panelRect, 24, 40, 29, 238);
    fillRect(app.renderer, SDL_FRect{app.panelRect.x, app.panelRect.y, app.panelRect.w, 34.0f}, 31, 55, 40, 242);
    strokeRect(app.renderer, app.panelRect, 238, 223, 173, 120);
    setColor(app.renderer, 248, 241, 214, 255);
    uiText(app.renderer, app.panelRect.x + 14.0f, app.panelRect.y + 10.0f, panelTitle(app.currentTab), 0.92f);
    app.panelCloseRect = SDL_FRect{app.panelRect.x + app.panelRect.w - 40.0f, app.panelRect.y + 6.0f, 26.0f, 22.0f};
    drawButton(app.renderer, app.panelCloseRect, "X", 228, 195, 104, 0.68f, isPressed(app, PressTargetType::PanelClose));

    switch (app.currentTab) {
    case PanelTab::Seeds:
        drawSeedsPanel(app);
        break;
    case PanelTab::Orders:
        drawOrdersPanel(app);
        break;
    case PanelTab::Storage:
        drawStoragePanel(app);
        break;
    case PanelTab::Upgrade:
        drawUpgradePanel(app);
        break;
    }
}

void drawStatus(App& app) {
    fillRect(app.renderer, SDL_FRect{16.0f, 146.0f, 448.0f, 30.0f}, 19, 44, 31, 164);
    setColor(app.renderer, 249, 242, 216, 255);
    uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(app.status, 0.9f) * 0.5f, 153.0f, app.status, 0.9f);
}

void drawHarvestFlies(App& app) {
    for (const HarvestFly& fly : app.harvestFlies) {
        const float t = std::clamp(fly.elapsed / fly.duration, 0.0f, 1.0f);
        const float eased = easeOutCubic(t);
        const float arc = std::sin(t * 3.1415926535f) * 34.0f;
        const float x = fly.start.x + (fly.end.x - fly.start.x) * eased;
        const float y = fly.start.y + (fly.end.y - fly.start.y) * eased - arc;
        const float size = fly.size * (1.0f - 0.25f * easeInCubic(t));
        fillCircle(app.renderer, x, y, size, fly.color.r, fly.color.g, fly.color.b, 235);
        fillCircle(app.renderer, x, y, size * 0.46f, 255, 248, 220, 220);
    }
}

void drawToast(App& app) {
    if (app.toastTimer <= 0.0f || app.toastText.empty()) {
        return;
    }
    const float fadeWindow = std::min(0.22f, app.toastDuration * 0.35f);
    float alpha = 1.0f;
    if (app.toastTimer < fadeWindow) {
        alpha = app.toastTimer / fadeWindow;
    }
    const float offset = (1.0f - alpha) * 12.0f;
    const float width = std::min(420.0f, uiTextWidth(app.toastText, 0.92f) + 44.0f);
    const SDL_FRect rect{(kBaseWidth - width) * 0.5f, 694.0f + offset, width, 42.0f};
    fillRect(app.renderer, rect, app.toastColor.r, app.toastColor.g, app.toastColor.b, static_cast<std::uint8_t>(app.toastColor.a * alpha));
    strokeRect(app.renderer, rect, app.toastBorderColor.r, app.toastBorderColor.g, app.toastBorderColor.b, static_cast<std::uint8_t>(app.toastBorderColor.a * alpha));
    setColor(app.renderer, 252, 247, 225, static_cast<std::uint8_t>(255.0f * alpha));
    uiText(app.renderer, rect.x + rect.w * 0.5f - uiTextWidth(app.toastText, 0.92f) * 0.5f, rect.y + 13.0f, app.toastText, 0.92f);
}

void drawBanner(App& app) {
    if (app.bannerTimer <= 0.0f || app.bannerTitle.empty()) {
        return;
    }
    const SDL_FRect panel{78.0f, 84.0f, 324.0f, 74.0f};
    fillRect(app.renderer, panel, 7, 24, 17, 188);
    strokeRect(app.renderer, panel, 252, 208, 102, 190);
    setColor(app.renderer, 255, 245, 214, 255);
    uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(app.bannerTitle, 1.12f) * 0.5f, panel.y + 14.0f, app.bannerTitle, 1.12f);
    if (!app.bannerSubtitle.empty()) {
        uiText(app.renderer, kBaseWidth * 0.5f - uiTextWidth(app.bannerSubtitle, 0.84f) * 0.5f, panel.y + 42.0f, app.bannerSubtitle, 0.84f);
    }
}

void drawMenuOverlay(App& app) {
    fillRect(app.renderer, SDL_FRect{0, 0, kBaseWidth, kBaseHeight}, 0, 0, 0, 120);
    const SDL_FRect panel{108.0f, 268.0f, 264.0f, 122.0f};
    fillRect(app.renderer, panel, 243, 233, 198, 248);
    strokeRect(app.renderer, panel, 73, 57, 39);
    setColor(app.renderer, 36, 28, 20, 255);
    uiText(app.renderer, panel.x + 24.0f, panel.y + 20.0f, "Menu", 1.1f);
    app.menuCloseRect = SDL_FRect{panel.x + panel.w - 38.0f, panel.y + 14.0f, 24.0f, 24.0f};
    drawButton(app.renderer, app.menuCloseRect, "X", 232, 201, 118, 0.72f, isPressed(app, PressTargetType::MenuClose));
    app.menuLobbyRect = SDL_FRect{panel.x + 28.0f, panel.y + 62.0f, panel.w - 56.0f, 40.0f};
    drawButton(app.renderer, app.menuLobbyRect, "Lobby", 174, 216, 172, 0.92f, isPressed(app, PressTargetType::MenuLobby));
}

void drawApp(App& app) {
    SDL_SetRenderLogicalPresentation(app.renderer, kBaseWidth, kBaseHeight, SDL_LOGICAL_PRESENTATION_LETTERBOX);
    drawBackground(app);
    drawTopBar(app);
    drawStatus(app);
    drawGrid(app);
    drawHarvestFlies(app);
    drawBottomTabs(app);
    drawPanel(app);
    drawBanner(app);
    drawToast(app);
    if (app.menuOpen) {
        drawMenuOverlay(app);
    }
    SDL_RenderPresent(app.renderer);
}

void saveApp(App& app) {
    app.farm.lastSaveTime = nowSeconds();
    saveFarm(app.farm);
}

void handlePlotTap(App& app, int plotIndex) {
    if (plotIndex < 0 || plotIndex >= static_cast<int>(app.farm.plots.size())) {
        return;
    }
    Plot& plot = app.farm.plots[static_cast<std::size_t>(plotIndex)];
    app.selectedPlot = plotIndex;
    if (plot.state == PlotState::Locked) {
        showToast(app, "Unlock more farm rank to open this plot.", true);
        return;
    }
    if (plot.state == PlotState::Ready) {
        std::string resultLabel;
        const std::string harvestedCropId = plot.cropId;
        if (harvestPlot(app.farm, plotIndex, app.rng, resultLabel)) {
            if (const CropDef* crop = findCropDef(harvestedCropId)) {
                spawnHarvestFly(app, plotIndex, crop->color, 3);
            }
            showToast(app, resultLabel, false, 1.6f);
            maybeRankUp(app);
            saveApp(app);
        }
        return;
    }
    if (plot.state == PlotState::Growing) {
        showToast(app, cropShortName(plot.cropId) + " ready in " + formatDuration(std::max(0.0, plot.growSeconds - (nowSeconds() - plot.plantedAt))), false, 1.2f);
        return;
    }
    const CropDef* crop = findCropDef(app.selectedSeedId);
    if (!crop) {
        showToast(app, "Choose a seed first.", true);
        return;
    }
    if (plantCrop(app.farm, plotIndex, *crop, nowSeconds())) {
        showToast(app, "Planted " + crop->name + ".", false, 1.2f);
        saveApp(app);
    } else {
        showToast(app, "Not enough coins to plant " + crop->name + ".", true);
    }
}

void handleOrderTap(App& app, int orderIndex) {
    if (orderIndex < 0 || orderIndex >= static_cast<int>(app.farm.orders.size())) {
        return;
    }
    if (completeOrder(app.farm, app.farm.orders[static_cast<std::size_t>(orderIndex)])) {
        showToast(app, "Order complete. Coins +" + std::to_string(app.farm.orders[static_cast<std::size_t>(orderIndex)].coinReward));
        app.farm.orders.erase(app.farm.orders.begin() + static_cast<std::ptrdiff_t>(orderIndex));
        refillOrders(app.farm, app.rng);
        maybeRankUp(app);
        saveApp(app);
    } else {
        showToast(app, "Storage missing crops for this order.", true);
    }
}

void handleStorageSell(App& app, const std::string& cropId) {
    const CropDef* crop = findCropDef(cropId);
    if (!crop) {
        return;
    }
    int& amount = app.farm.storage[cropId];
    if (amount <= 0) {
        showToast(app, "No " + crop->name + " to sell.", true);
        return;
    }
    const int coins = amount * crop->sellPrice;
    app.farm.coins += coins;
    app.farm.totalCoinsEarned += coins;
    amount = 0;
    showToast(app, "Sold all " + crop->name + " for " + std::to_string(coins) + " coins.");
    maybeRankUp(app);
    saveApp(app);
}

void handleUpgradeTap(App& app) {
    if (app.selectedPlot < 0 || app.selectedPlot >= static_cast<int>(app.farm.plots.size())) {
        showToast(app, "Select a plot first.", true);
        return;
    }
    Plot& plot = app.farm.plots[static_cast<std::size_t>(app.selectedPlot)];
    if (plot.state == PlotState::Locked) {
        showToast(app, "Locked plot cannot be upgraded.", true);
        return;
    }
    if (plot.level >= 5) {
        showToast(app, "This plot is already max level.", true);
        return;
    }
    const int cost = plotUpgradeCost(plot.level);
    if (app.farm.coins < cost) {
        showToast(app, "Need " + std::to_string(cost) + " coins.", true);
        return;
    }
    app.farm.coins -= cost;
    ++plot.level;
    showToast(app, "Plot upgraded to level " + std::to_string(plot.level) + ".");
    maybeRankUp(app);
    saveApp(app);
}

void handlePointerDown(App& app, float x, float y) {
    clearPressedTarget(app);
    if (app.menuOpen) {
        if (pointInRect(x, y, app.menuCloseRect)) {
            app.pressedTarget = PressTargetType::MenuClose;
            return;
        }
        if (pointInRect(x, y, app.menuLobbyRect)) {
            app.pressedTarget = PressTargetType::MenuLobby;
            return;
        }
        return;
    }

    if (pointInRect(x, y, app.menuRect)) {
        app.pressedTarget = PressTargetType::Menu;
        return;
    }

    for (int i = 0; i < 4; ++i) {
        if (pointInRect(x, y, app.tabRects[static_cast<std::size_t>(i)])) {
            app.pressedTarget = PressTargetType::Tab;
            app.pressedTargetIndex = i;
            return;
        }
    }

    if (!app.panelOpen) {
        return;
    }

    if (pointInRect(x, y, app.panelCloseRect)) {
        app.pressedTarget = PressTargetType::PanelClose;
        return;
    }

    switch (app.currentTab) {
    case PanelTab::Seeds:
        for (std::size_t i = 0; i < app.seedRects.size(); ++i) {
            if (pointInRect(x, y, app.seedRects[i])) {
                app.pressedTarget = PressTargetType::Seed;
                app.pressedTargetIndex = static_cast<int>(i);
                return;
            }
        }
        break;
    case PanelTab::Orders:
        for (std::size_t i = 0; i < app.orderRects.size(); ++i) {
            if (pointInRect(x, y, app.orderRects[i])) {
                app.pressedTarget = PressTargetType::Order;
                app.pressedTargetIndex = static_cast<int>(i);
                return;
            }
        }
        break;
    case PanelTab::Storage:
        for (std::size_t i = 0; i < app.storageSellRects.size(); ++i) {
            if (pointInRect(x, y, app.storageSellRects[i].second)) {
                app.pressedTarget = PressTargetType::StorageSell;
                app.pressedTargetIndex = static_cast<int>(i);
                return;
            }
        }
        break;
    case PanelTab::Upgrade:
        if (pointInRect(x, y, app.upgradeButtonRect)) {
            app.pressedTarget = PressTargetType::Upgrade;
            return;
        }
        break;
    }
}

void handlePointerUp(App& app, float x, float y) {
    const PressTargetType pressedTarget = app.pressedTarget;
    const int pressedTargetIndex = app.pressedTargetIndex;
    clearPressedTarget(app);
    if (app.menuOpen) {
        if (pressedTarget == PressTargetType::MenuClose && pointInRect(x, y, app.menuCloseRect)) {
            app.menuOpen = false;
            return;
        }
        if (pressedTarget == PressTargetType::MenuLobby && pointInRect(x, y, app.menuLobbyRect)) {
            app.exitAction = FarmExitAction::BackToLobby;
            app.running = false;
            return;
        }
        app.menuOpen = false;
        return;
    }

    if (pressedTarget == PressTargetType::Menu && pointInRect(x, y, app.menuRect)) {
        app.menuOpen = true;
        return;
    }

    for (int i = 0; i < 4; ++i) {
        if (pressedTarget == PressTargetType::Tab && pressedTargetIndex == i && pointInRect(x, y, app.tabRects[static_cast<std::size_t>(i)])) {
            const PanelTab nextTab = static_cast<PanelTab>(i);
            if (app.panelOpen && app.currentTab == nextTab) {
                app.panelOpen = false;
            } else {
                app.currentTab = nextTab;
                app.panelOpen = true;
            }
            return;
        }
    }

    if (app.panelOpen) {
        if (pressedTarget == PressTargetType::PanelClose && pointInRect(x, y, app.panelCloseRect)) {
            app.panelOpen = false;
            return;
        }

        switch (app.currentTab) {
        case PanelTab::Seeds:
            for (std::size_t i = 0; i < app.seedRects.size(); ++i) {
                if (pressedTarget == PressTargetType::Seed && pressedTargetIndex == static_cast<int>(i) && pointInRect(x, y, app.seedRects[i])) {
                    const auto unlocked = unlockedCropIndices(app.farm);
                    if (i < unlocked.size()) {
                        app.selectedSeedId = cropDefs()[unlocked[i]].id;
                        showToast(app, "Selected " + cropDefs()[unlocked[i]].name + ".", false, 1.0f);
                        app.panelOpen = false;
                        return;
                    }
                }
            }
            break;
        case PanelTab::Orders:
            for (std::size_t i = 0; i < app.orderRects.size(); ++i) {
                if (pressedTarget == PressTargetType::Order && pressedTargetIndex == static_cast<int>(i) && pointInRect(x, y, app.orderRects[i])) {
                    handleOrderTap(app, static_cast<int>(i));
                    return;
                }
            }
            break;
        case PanelTab::Storage:
            for (std::size_t i = 0; i < app.storageSellRects.size(); ++i) {
                if (pressedTarget == PressTargetType::StorageSell && pressedTargetIndex == static_cast<int>(i) && pointInRect(x, y, app.storageSellRects[i].second)) {
                    handleStorageSell(app, app.storageSellRects[i].first);
                    return;
                }
            }
            break;
        case PanelTab::Upgrade:
            if (pressedTarget == PressTargetType::Upgrade && pointInRect(x, y, app.upgradeButtonRect)) {
                handleUpgradeTap(app);
                return;
            }
            break;
        }

        if (pointInRect(x, y, app.panelRect)) {
            return;
        }
        app.panelOpen = false;
        return;
    }

    for (std::size_t i = 0; i < app.plotRects.size(); ++i) {
        if (pointInRect(x, y, app.plotRects[i])) {
            handlePlotTap(app, static_cast<int>(i));
            return;
        }
    }
}

void updateApp(App& app, float delta) {
    app.elapsed += delta;
    app.bannerTimer = std::max(0.0f, app.bannerTimer - delta);
    app.toastTimer = std::max(0.0f, app.toastTimer - delta);
    updateFarmGrowth(app.farm, nowSeconds());
    for (HarvestFly& fly : app.harvestFlies) {
        fly.elapsed += delta;
    }
    app.harvestFlies.erase(std::remove_if(app.harvestFlies.begin(), app.harvestFlies.end(), [](const HarvestFly& fly) {
        return fly.elapsed >= fly.duration;
    }), app.harvestFlies.end());
}

bool init(App& app, const AppWindowState& initialWindowState) {
    SDL_SetAppMetadata("Tiny Golden Farm", "0.1.0", "com.gamestudio.farm");
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return false;
    }
    app.window = SDL_CreateWindow("Tiny Golden Farm", kBaseWidth, kBaseHeight, SDL_WINDOW_RESIZABLE);
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
    app.plotRects = makePlotRects();
    loadOrResetFarm(app);
    return true;
}

void shutdown(App& app) {
    saveApp(app);
    if (app.renderer) SDL_DestroyRenderer(app.renderer);
    if (app.window) SDL_DestroyWindow(app.window);
    SDL_Quit();
}

}  // namespace

FarmRunResult runFarmApp(const AppWindowState& initialWindowState) {
    App app;
    if (!init(app, initialWindowState)) {
        shutdown(app);
        return FarmRunResult{FarmExitAction::Quit, initialWindowState};
    }

    std::uint64_t lastTicks = SDL_GetTicks();
    while (app.running) {
        const std::uint64_t nowTicks = SDL_GetTicks();
        const float delta = std::min(0.033f, static_cast<float>(nowTicks - lastTicks) / 1000.0f);
        lastTicks = nowTicks;

        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                app.exitAction = FarmExitAction::Quit;
                app.running = false;
            } else if (event.type == SDL_EVENT_KEY_DOWN) {
                if (event.key.key == SDLK_ESCAPE) {
                    app.exitAction = FarmExitAction::Quit;
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

        updateApp(app, delta);
        drawApp(app);
        SDL_Delay(16);
    }

    app.windowState = snapshotWindowState(app.window);
    const FarmRunResult result{app.exitAction, app.windowState};
    shutdown(app);
    return result;
}
