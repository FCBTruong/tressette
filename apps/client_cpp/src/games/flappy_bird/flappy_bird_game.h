#pragma once

#include "../../app_window_state.h"

enum class FlappyBirdExitAction {
    Quit,
    BackToLobby,
};

struct FlappyBirdRunResult {
    FlappyBirdExitAction action = FlappyBirdExitAction::Quit;
    AppWindowState windowState{};
};

FlappyBirdRunResult runFlappyBirdApp(const AppWindowState& initialWindowState);