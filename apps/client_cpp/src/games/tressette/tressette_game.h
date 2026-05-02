#pragma once

#include "../../app_window_state.h"

enum class TressetteExitAction {
    Quit,
    BackToLobby,
};

struct TressetteRunResult {
    TressetteExitAction action = TressetteExitAction::Quit;
    AppWindowState windowState{};
};

TressetteRunResult runTressetteApp(const AppWindowState& initialWindowState);