#pragma once

#include "../../app_window_state.h"

enum class ScopaExitAction {
    Quit,
    BackToLobby,
};

struct ScopaRunResult {
    ScopaExitAction action = ScopaExitAction::Quit;
    AppWindowState windowState{};
};

ScopaRunResult runScopaApp(const AppWindowState& initialWindowState);