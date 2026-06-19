pragma Singleton

import Quickshell
import Quickshell.Hyprland as QsHyprland
import QtQuick

// Serviço do estado do Hyprland. Na Fase 7, a única ação mutável permitida
// aqui é a ativação controlada de um workspace real.
Singleton {
    id: root

    readonly property var _hypr: QsHyprland.Hyprland
    readonly property string _fallback: "\u2014"
    readonly property string _noActiveWindow: "Sem janela ativa"

    readonly property bool available: !!root._hypr.requestSocketPath && !!root._hypr.eventSocketPath

    readonly property string requestSocketPath: root._safeString(root._hypr.requestSocketPath, "")
    readonly property string eventSocketPath: root._safeString(root._hypr.eventSocketPath, "")

    readonly property var monitors: root._hypr.monitors
    readonly property var workspaces: root._hypr.workspaces
    readonly property var focusedMonitor: root._hypr.focusedMonitor
    readonly property var focusedWorkspace: root._hypr.focusedWorkspace
    readonly property var activeToplevel: root._hypr.activeToplevel
    readonly property var workspaceList: {
        const list = root._modelValues(root.workspaces);

        list.sort(function(a, b) {
            const aKey = root.workspaceSortKey(a);
            const bKey = root.workspaceSortKey(b);

            if (aKey < bKey)
                return -1;
            if (aKey > bKey)
                return 1;

            const aLabel = root.workspaceLabel(a).toLowerCase();
            const bLabel = root.workspaceLabel(b).toLowerCase();
            if (aLabel < bLabel)
                return -1;
            if (aLabel > bLabel)
                return 1;

            return 0;
        });

        return list;
    }

    readonly property string activeWindowTitle: {
        if (!root.activeToplevel)
            return root._noActiveWindow;

        const title = root._safeString(root.activeToplevel.title, "");
        if (title)
            return title;

        const object = root.activeToplevel.lastIpcObject;
        const ipcTitle = root._safeString(object ? object["title"] : "", "");
        if (ipcTitle)
            return ipcTitle;

        const initialTitle = root._safeString(object ? object["initialTitle"] : "", "");
        if (initialTitle)
            return initialTitle;

        return root._noActiveWindow;
    }

    readonly property string activeWindowClass: {
        if (!root.activeToplevel)
            return root._fallback;

        const object = root.activeToplevel.lastIpcObject;
        const className = root._safeString(object ? object["class"] : "", "");
        if (className)
            return className;

        const initialClass = root._safeString(object ? object["initialClass"] : "", "");
        if (initialClass)
            return initialClass;

        return root._fallback;
    }

    readonly property string focusedMonitorName: root._monitorName(root.focusedMonitor)
    readonly property string focusedWorkspaceName: root.workspaceLabel(root.focusedWorkspace)
    readonly property string activeWorkspaceLabel: root.workspaceLabel(root.focusedMonitor && root.focusedMonitor.activeWorkspace ? root.focusedMonitor.activeWorkspace : root.focusedWorkspace)
    readonly property string activeWindowSummary: {
        if (root.activeWindowTitle === root._noActiveWindow)
            return root._noActiveWindow;

        if (root.activeWindowClass === root._fallback)
            return root.activeWindowTitle;

        return root.activeWindowClass + " \u00b7 " + root.activeWindowTitle;
    }

    function workspaceLabel(workspace) {
        if (!workspace)
            return root._fallback;

        const name = root._safeString(workspace.name, "");
        if (name) {
            if (name.indexOf("special:") === 0) {
                const specialName = name.slice(8);
                return root._safeString(specialName, "special");
            }

            return name;
        }

        if (workspace.id !== undefined && workspace.id !== null && workspace.id >= 0)
            return root._safeString(workspace.id, root._fallback);

        return root._fallback;
    }

    function isWorkspaceActive(workspace) {
        return !!(workspace && workspace.active);
    }

    function isWorkspaceFocused(workspace) {
        return !!(workspace && workspace.focused);
    }

    function isWorkspaceUrgent(workspace) {
        return !!(workspace && workspace.urgent);
    }

    function isRealWorkspace(workspace) {
        return !!root._resolveWorkspace(workspace);
    }

    function canActivateWorkspace(workspace) {
        const target = root._resolveWorkspace(workspace);

        return !!(target && !root.isWorkspaceFocused(target) && !root.isWorkspaceActive(target));
    }

    function activateWorkspace(workspace) {
        const target = root._resolveWorkspace(workspace);

        if (!target || root.isWorkspaceFocused(target) || root.isWorkspaceActive(target))
            return false;

        // Fase 7: única ação mutável permitida. Preferimos a API typed do
        // workspace e mantemos o activate() encapsulado apenas neste serviço.
        target.activate();
        return true;
    }

    // ---- foco de janela existente ("me leve até o app") ----
    // Procura um toplevel cuja class/initialClass case com algum dos hints e o
    // foca via IPC typed do Hyprland (dispatch — não é Process). Retorna true se
    // focou. Usado pelo launcher para "raise" em vez de abrir nova instância.
    function findToplevelByClass(hints) {
        if (!hints || hints.length === 0)
            return null;

        const tops = root._modelValues(root._hypr.toplevels);
        for (let i = 0; i < tops.length; i++) {
            const top = tops[i];
            const cls = root._toplevelClassText(top);
            if (!cls)
                continue;

            for (let h = 0; h < hints.length; h++) {
                const hint = root._safeString(hints[h], "").toLowerCase();
                if (hint && cls.indexOf(hint) >= 0)
                    return top;
            }
        }

        return null;
    }

    function raiseByClass(hints) {
        const top = root.findToplevelByClass(hints);
        if (!top || !top.address)
            return false;

        // address vem como "0x...." — focuswindow troca de workspace se preciso.
        root._hypr.dispatch("focuswindow address:" + top.address);
        return true;
    }

    // ---- visão por workspace (alt-tab agrupado) ----
    // Lista de toplevels (HyprlandToplevel) de um workspace. Cada item tem
    // `.wayland` (capturável pelo ScreencopyView), `.address`, `.title`, `.activated`.
    function workspaceToplevels(workspace) {
        return root._modelValues(workspace ? workspace.toplevels : null);
    }

    // Rótulo de app de um toplevel do Hyprland (class > initialClass > title).
    function toplevelLabel(toplevel) {
        return root._toplevelAppLabel(toplevel);
    }

    // Foca uma janela específica pelo address — IPC typed (dispatch), não Process.
    // Troca de workspace se preciso. Mais robusto que activate() do Wayland.
    function focusToplevel(toplevel) {
        if (!toplevel || !toplevel.address)
            return false;

        root._hypr.dispatch("focuswindow address:" + toplevel.address);
        return true;
    }

    // Fecha graciosamente uma janela: prefere close() typed do Wayland (o app
    // pode pedir para salvar); cai no dispatch closewindow se não houver handle.
    function closeToplevel(toplevel) {
        if (!toplevel)
            return false;

        if (toplevel.wayland) {
            toplevel.wayland.close();
            return true;
        }

        if (toplevel.address) {
            root._hypr.dispatch("closewindow address:" + toplevel.address);
            return true;
        }

        return false;
    }

    // Fecha todas as janelas de um workspace (ação destrutiva — a UI confirma).
    function closeWorkspace(workspace) {
        const tops = root.workspaceToplevels(workspace);
        for (let i = 0; i < tops.length; i++)
            root.closeToplevel(tops[i]);
        return tops.length > 0;
    }

    function _toplevelClassText(toplevel) {
        if (!toplevel)
            return "";

        const object = toplevel.lastIpcObject;
        const className = root._safeString(object ? object["class"] : "", "");
        const initialClass = root._safeString(object ? object["initialClass"] : "", "");
        return (className + " " + initialClass).toLowerCase().trim();
    }

    function workspaceSortKey(workspace) {
        if (!workspace)
            return "9:~";

        const name = root._safeString(workspace.name, "");
        const parsedName = Number(name);

        if (workspace.id !== undefined && workspace.id !== null && workspace.id >= 0)
            return "0:" + root._padNumber(workspace.id);

        if (name && !Number.isNaN(parsedName))
            return "1:" + root._padNumber(parsedName);

        if (name.indexOf("special:") === 0)
            return "8:" + name.toLowerCase();

        return "4:" + root.workspaceLabel(workspace).toLowerCase();
    }

    function workspaceWindowCount(workspace) {
        if (!workspace)
            return 0;

        const object = workspace.lastIpcObject;
        const windows = object ? Number(object["windows"]) : NaN;
        if (!Number.isNaN(windows) && windows >= 0)
            return Math.trunc(windows);

        return root._modelValues(workspace.toplevels).length;
    }

    function workspaceHasWindows(workspace) {
        return root.workspaceWindowCount(workspace) > 0;
    }

    function workspaceStatusLabel(workspace) {
        if (!workspace)
            return root._fallback;

        if (root.isWorkspaceFocused(workspace))
            return "Focado";
        if (root.isWorkspaceActive(workspace))
            return "Ativo";
        if (root.isWorkspaceUrgent(workspace))
            return "Urgente";

        return root.workspaceHasWindows(workspace) ? "Ocupado" : "Vazio";
    }

    function workspaceWindowSummary(workspace) {
        if (!workspace)
            return "Vazio";

        const count = root.workspaceWindowCount(workspace);
        if (count <= 0)
            return "Vazio";

        const toplevels = root._modelValues(workspace.toplevels);
        const labels = [];
        const seen = {};

        for (let i = 0; i < toplevels.length; i++) {
            const label = root._toplevelAppLabel(toplevels[i]);
            const key = label.toLowerCase();

            if (label !== root._fallback && !seen[key]) {
                seen[key] = true;
                labels.push(label);
            }
        }

        if (labels.length === 0)
            return count === 1 ? "1 janela aberta" : count + " janelas abertas";

        if (count === 1)
            return labels[0];
        if (labels.length === 1)
            return labels[0] + " +" + Math.max(0, count - 1);
        if (count === 2 && labels.length >= 2)
            return labels[0] + ", " + labels[1];

        return labels[0] + ", " + labels[1] + " +" + Math.max(0, count - 2);
    }

    function monitorForScreen(screen) {
        if (!root.available || !screen)
            return null;

        const directMatch = root._hypr.monitorFor(screen);
        if (directMatch)
            return directMatch;

        const screenName = root._safeString(screen.name, "");
        if (!screenName)
            return null;

        const monitorList = root._modelValues(root.monitors);
        for (let i = 0; i < monitorList.length; i++) {
            const monitor = monitorList[i];
            if (monitor && monitor.name === screenName)
                return monitor;
        }

        return null;
    }

    function workspacesForMonitorName(name) {
        if (!name)
            return [];

        const list = root.workspaceList;
        const filtered = [];

        for (let i = 0; i < list.length; i++) {
            const workspace = list[i];
            if (workspace && workspace.monitor && workspace.monitor.name === name)
                filtered.push(workspace);
        }

        return filtered;
    }

    function workspacesForScreen(screen) {
        if (!root.available)
            return [];

        const monitor = root.monitorForScreen(screen);

        if (monitor && monitor.name) {
            const filtered = root.workspacesForMonitorName(monitor.name);
            if (filtered.length > 0)
                return filtered;
        }

        return root.workspaceList;
    }

    function activeWorkspaceForScreen(screen) {
        const monitor = root.monitorForScreen(screen);
        if (monitor && monitor.activeWorkspace)
            return monitor.activeWorkspace;

        const workspaces = root.workspacesForScreen(screen);
        for (let i = 0; i < workspaces.length; i++) {
            const workspace = workspaces[i];
            if (root.isWorkspaceFocused(workspace) || root.isWorkspaceActive(workspace))
                return workspace;
        }

        return null;
    }

    function monitorNameForScreen(screen) {
        const monitor = root.monitorForScreen(screen);
        if (monitor)
            return root._monitorName(monitor);

        const screenName = root._safeString(screen && screen.name ? screen.name : "", "");
        if (screenName)
            return screenName;

        return root._fallback;
    }

    function _resolveWorkspace(workspace) {
        if (!workspace)
            return null;

        const list = root.workspaceList;

        for (let i = 0; i < list.length; i++) {
            const candidate = list[i];

            if (candidate === workspace)
                return root._hasWorkspaceIdentity(candidate) ? candidate : null;
        }

        return null;
    }

    function _hasWorkspaceIdentity(workspace) {
        if (!workspace)
            return false;

        const name = root._safeString(workspace.name, "");
        if (name)
            return true;

        return workspace.id !== undefined && workspace.id !== null && Number(workspace.id) >= 0;
    }

    function _modelValues(model) {
        if (!model || !model.values || !model.values.slice)
            return [];

        return model.values.slice();
    }

    function _monitorName(monitor) {
        return root._safeString(monitor && monitor.name ? monitor.name : "", root._fallback);
    }

    function _toplevelAppLabel(toplevel) {
        if (!toplevel)
            return root._fallback;

        const object = toplevel.lastIpcObject;
        const className = root._safeString(object ? object["class"] : "", "");
        if (className)
            return className;

        const initialClass = root._safeString(object ? object["initialClass"] : "", "");
        if (initialClass)
            return initialClass;

        const title = root._safeString(toplevel.title, "");
        if (title)
            return title;

        return root._fallback;
    }

    function _padNumber(value) {
        let text = String(Math.max(0, Math.trunc(Number(value) || 0)));

        while (text.length < 8)
            text = "0" + text;

        return text;
    }

    function _safeString(value, fallback) {
        if (value === undefined || value === null)
            return fallback;

        const text = String(value).trim();
        return text.length > 0 ? text : fallback;
    }
}
