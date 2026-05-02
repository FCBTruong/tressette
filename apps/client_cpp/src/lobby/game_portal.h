#pragma once

#include "../app_window_state.h"

enum class PortalSelection {
    Quit,
    Tressette,
    MemoryCards,
};

struct PortalResult {
    PortalSelection selection = PortalSelection::Quit;
    AppWindowState windowState{};
};

PortalResult runGamePortal(const AppWindowState& initialWindowState);