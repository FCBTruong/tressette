#pragma once

struct AppWindowState {
    int width = 480;
    int height = 854;
    int posX = 0;
    int posY = 0;
    bool hasPosition = false;
    bool maximized = false;
    bool fullscreen = false;
};