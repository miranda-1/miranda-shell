//@ pragma Env QSG_RENDER_LOOP=threaded

import "modules/EdgeLeft"
import "modules/TopSheet"
import "services"
import Quickshell

// Entrypoint da shell. Depois do install.sh (symlink em ~/.config/quickshell/
// miranda-shell), roda com:  qs -c miranda-shell   — ou, a partir do repo:  qs -p ./shell.qml
// Convive com a Waybar do HyDE — não substitui nada até você optar pelo deploy.
ShellRoot {
    // Uma instância de cada borda por tela. O Scope agrupa as janelas e repassa
    // o `modelData` (a tela) injetado pelo Variants.
    Variants {
        // Por padrão o shell aparece em todas as telas. Se o usuário escolher um
        // monitor específico na página "Telas" (Monitors.shellMonitor), filtra
        // para só essa tela; se a tela escolhida não existir nesta sessão, volta
        // a mostrar em todas (fallback seguro).
        model: {
            const all = Quickshell.screens;
            const chosen = Monitors.shellMonitor;
            if (!chosen)
                return all;

            const match = all.filter(s => s && s.name === chosen);
            return match.length > 0 ? match : all;
        }
        delegate: Scope {
            id: scope
            required property var modelData
            property string currentPage: "dashboard"
            property bool contextOpen: false

            function toggleContextPage(pageId) {
                if (scope.contextOpen && scope.currentPage === pageId) {
                    scope.contextOpen = false;
                    return;
                }

                scope.currentPage = pageId;
                scope.contextOpen = true;
            }

            function closeContext() {
                scope.contextOpen = false;
            }

            EdgeLeft {
                modelData: scope.modelData
                currentPage: scope.currentPage
                contextOpen: scope.contextOpen
                onRequestPage: (pageId) => scope.toggleContextPage(pageId)
            }

            TopSheet {
                modelData: scope.modelData
                currentPage: scope.currentPage
                open: scope.contextOpen
                onRequestClose: scope.closeContext()
            }
        }
    }
}
