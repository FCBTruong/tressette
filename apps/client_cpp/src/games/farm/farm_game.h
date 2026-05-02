#pragma once

#include "../../app_window_state.h"

enum class FarmExitAction {
    Quit,
    BackToLobby,
};

struct FarmRunResult {
    FarmExitAction action = FarmExitAction::Quit;
    AppWindowState windowState{};
};

FarmRunResult runFarmApp(const AppWindowState& initialWindowState);