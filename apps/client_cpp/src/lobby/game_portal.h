#pragma once

#include "../app_window_state.h"

enum class PortalSelection {
    Quit,
    Tressette,
    Farm,
    MemoryCards,
    FlappyBird,
    Scopa,
};

struct PortalResult {
    PortalSelection selection = PortalSelection::Quit;
    AppWindowState windowState{};
};

PortalResult runGamePortal(const AppWindowState& initialWindowState);