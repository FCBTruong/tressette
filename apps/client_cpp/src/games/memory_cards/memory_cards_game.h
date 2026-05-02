#pragma once

#include "../../app_window_state.h"

enum class MemoryCardsExitAction {
    Quit,
    BackToLobby,
};

struct MemoryCardsRunResult {
    MemoryCardsExitAction action = MemoryCardsExitAction::Quit;
    AppWindowState windowState{};
};

MemoryCardsRunResult runMemoryCardsApp(const AppWindowState& initialWindowState);