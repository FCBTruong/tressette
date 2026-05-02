#include "games/tressette/tressette_game.h"
#include "games/memory_cards/memory_cards_game.h"
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

        if (portalResult.selection == PortalSelection::MemoryCards) {
            showLoadingScene(windowState, "Memory Cards", "Opening game...");
            const MemoryCardsRunResult gameResult = runMemoryCardsApp(windowState);
            windowState = gameResult.windowState;
            if (gameResult.action == MemoryCardsExitAction::Quit) {
                return 0;
            }

            showLoadingScene(windowState, "Game Portal", "Returning to portal...");
        }
    }
}
