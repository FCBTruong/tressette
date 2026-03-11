#pragma once

class GameConstants {
public:
    static constexpr int EMPTY_PLAYER_UID = -1;
	static constexpr int TIME_AUTO_PLAY = 15; // seconds to auto play after player turn
	static constexpr int TIME_AUTO_PLAY_SEVERE = 1; // seconds to auto play after player turn when severe (e.g. last won player is auto play)
	static constexpr bool DEV_MODE = true; // If true, will use fixed cards for testing
};