#pragma once
#include <array>

class GameConstants {
public:
    static constexpr int EMPTY_PLAYER_UID = -1;
	static constexpr int TIME_AUTO_PLAY = 15; // seconds to auto play after player turn
	static constexpr int TIME_AUTO_PLAY_SEVERE = 1; // seconds to auto play after player turn when severe (e.g. last won player is auto play)
	static constexpr bool DEV_MODE = false; // If true, will use fixed cards for testing

	inline static constexpr std::array<int, 21> AVATAR_IDS = {
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
        12, 13, 14, 15, 16, 17, 18, 19, 20, 21
    };

	inline static constexpr int AVATAR_FRAME_DEFAULT = 1000;
	inline static constexpr int AVATAR_FRAME_SEASON = 1001;
	inline static constexpr int AVATAR_FRAME_VICTORY = 1002;
	inline static constexpr int AVATAR_FRAME_VIP = 1003;
	inline static constexpr int AVATAR_FRAME_GOLD = 1004;
	inline static constexpr int AVATAR_FRAME_LV50 = 1005;
	inline static constexpr int AVATAR_FRAME_LV100 = 1006;

	inline static constexpr std::array<int, 7> AVATAR_FRAME_IDS = {
		AVATAR_FRAME_DEFAULT,
		AVATAR_FRAME_SEASON,
		AVATAR_FRAME_VICTORY,
		AVATAR_FRAME_VIP,
		AVATAR_FRAME_GOLD,
		AVATAR_FRAME_LV50,
		AVATAR_FRAME_LV100
	};
};