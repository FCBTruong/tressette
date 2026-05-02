#include <SDL3/SDL_main.h>

#include "games/tressette/tressette_game.h"
#include "games/farm/farm_game.h"
#include "games/memory_cards/memory_cards_game.h"
#include "games/flappy_bird/flappy_bird_game.h"
#include "games/scopa/scopa_game.h"
#include "lobby/game_portal.h"
#include "loading_scene.h"

int main(int, char**) {
    AppWindowState windowState{};

    while (true) {
        const PortalResult portalResult = runGamePortal(windowState);
        windowState = portalResult.windowState;
        if (portalResult.selection == PortalSelection::Quit) {
            return 0;
        }

        if (portalResult.selection == PortalSelection::Tressette) {
            showLoadingScene(windowState, "Tressette", "Opening game...");
            const TressetteRunResult gameResult = runTressetteApp(windowState);
            windowState = gameResult.windowState;
            if (gameResult.action == TressetteExitAction::Quit) {
                return 0;
            }

            showLoadingScene(windowState, "Game Portal", "Returning to portal...");
        }

        if (portalResult.selection == PortalSelection::Farm) {
            showLoadingScene(windowState, "Tiny Golden Farm", "Opening game...");
            const FarmRunResult gameResult = runFarmApp(windowState);
            windowState = gameResult.windowState;
            if (gameResult.action == FarmExitAction::Quit) {
                return 0;
            }

            showLoadingScene(windowState, "Game Portal", "Returning to portal...");
        }

        if (portalResult.selection == PortalSelection::MemoryCards) {
            showLoadingScene(windowState, "Memory Cards", "Opening game...");
            const MemoryCardsRunResult gameResult = runMemoryCardsApp(windowState);
            windowState = gameResult.windowState;
            if (gameResult.action == MemoryCardsExitAction::Quit) {
                return 0;
            }

            showLoadingScene(windowState, "Game Portal", "Returning to portal...");
        }

        if (portalResult.selection == PortalSelection::FlappyBird) {
            showLoadingScene(windowState, "Flappy Bird", "Opening game...");
            const FlappyBirdRunResult gameResult = runFlappyBirdApp(windowState);
            windowState = gameResult.windowState;
            if (gameResult.action == FlappyBirdExitAction::Quit) {
                return 0;
            }

            showLoadingScene(windowState, "Game Portal", "Returning to portal...");
        }

        if (portalResult.selection == PortalSelection::Scopa) {
            showLoadingScene(windowState, "Scopa", "Opening game...");
            const ScopaRunResult gameResult = runScopaApp(windowState);
            windowState = gameResult.windowState;
            if (gameResult.action == ScopaExitAction::Quit) {
                return 0;
            }

            showLoadingScene(windowState, "Game Portal", "Returning to portal...");
        }
    }
}
