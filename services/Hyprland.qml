pragma Singleton

import Quickshell
import Quickshell.Hyprland as QsHyprland
import QtQuick

// Serviço read-only do estado do Hyprland para a Fase 6.
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

    function _modelValues(model) {
        if (!model || !model.values || !model.values.slice)
            return [];

        return model.values.slice();
    }

    function _monitorName(monitor) {
        return root._safeString(monitor && monitor.name ? monitor.name : "", root._fallback);
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
