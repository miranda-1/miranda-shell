import Quickshell
import QtQml

// Adapter read-only do índice de apps do Quickshell para um formato simples
// compatível com o delegate atual do Launcher.
QtObject {
    id: root

    property int limit: 4
    property string query: ""

    readonly property var sourceEntries: DesktopEntries.applications.values
    readonly property string normalizedQuery: query.trim().toLowerCase()
    readonly property var apps: buildApps(sourceEntries, limit, normalizedQuery)

    function joinStrings(values) {
        return Array.isArray(values) ? values.join(" ") : "";
    }

    function haystackFor(entry) {
        return [
            entry.name || "",
            entry.genericName || "",
            entry.comment || "",
            entry.icon || "",
            entry.execString || "",
            joinStrings(entry.command),
            joinStrings(entry.categories),
            joinStrings(entry.keywords)
        ].join(" ").toLowerCase();
    }

    function entryKey(entry) {
        return (entry.id || `${entry.name || ""}|${entry.execString || ""}`).toString();
    }

    function isTerminalEntry(entry, haystack) {
        const hints = [
            "kitty",
            "terminal",
            "alacritty",
            "konsole",
            "foot",
            "wezterm"
        ];

        for (const hint of hints) {
            if (haystack.indexOf(hint) >= 0)
                return true;
        }

        return false;
    }

    function isOperaEntry(entry, haystack) {
        return haystack.indexOf("opera browser") >= 0
            || haystack.indexOf("opera") >= 0;
    }

    function isCodeEntry(entry, haystack) {
        return haystack.indexOf("visual studio code") >= 0
            || haystack.indexOf("vscode") >= 0
            || haystack.indexOf("code-oss") >= 0
            || /\bcode\b/.test(haystack);
    }

    function isSpotifyEntry(entry, haystack) {
        return haystack.indexOf("spotify") >= 0;
    }

    function favoriteSpecs() {
        return [
            { label: "Opera", matcher: isOperaEntry },
            { label: "Terminal", matcher: isTerminalEntry },
            { label: "Visual Studio Code", matcher: isCodeEntry },
            { label: "Spotify", matcher: isSpotifyEntry }
        ];
    }

    function displayLabelForEntry(entry, haystack) {
        for (const favorite of favoriteSpecs()) {
            if (favorite.matcher(entry, haystack))
                return favorite.label;
        }

        return entry.name || "";
    }

    function normalizeEntry(entry, displayName) {
        const name = entry.name || "";
        const genericName = entry.genericName || "";
        const comment = entry.comment || "";
        const resolvedName = displayName || name;
        const subtitle = genericName.length ? genericName
            : comment.length ? comment
            : (resolvedName !== name ? name : "");
        const initial = resolvedName.trim().length ? resolvedName.trim().charAt(0).toUpperCase() : "?";

        return {
            desktopEntry: entry,
            name: resolvedName,
            desktopName: name,
            genericName: genericName,
            comment: comment,
            icon: entry.icon || "",
            iconSource: entry.icon ? Quickshell.iconPath(entry.icon, true) : "",
            categories: entry.categories || [],
            keywords: entry.keywords || [],
            execString: entry.execString || "",
            command: entry.command || [],
            runInTerminal: entry.runInTerminal || false,
            subtitle: subtitle,
            initial: initial
        };
    }

    function scoreEntry(entry, haystack, normalizedText) {
        const displayLabel = displayLabelForEntry(entry, haystack).toLowerCase();
        const name = (entry.name || "").toLowerCase();
        const genericName = (entry.genericName || "").toLowerCase();
        const comment = (entry.comment || "").toLowerCase();
        const execString = (entry.execString || "").toLowerCase();
        const categories = joinStrings(entry.categories).toLowerCase();
        const keywords = joinStrings(entry.keywords).toLowerCase();
        let score = -1;

        if (displayLabel === normalizedText || name === normalizedText)
            score = Math.max(score, 120);
        else if (displayLabel.indexOf(normalizedText) === 0 || name.indexOf(normalizedText) === 0)
            score = Math.max(score, 95);
        else if (displayLabel.indexOf(normalizedText) >= 0 || name.indexOf(normalizedText) >= 0)
            score = Math.max(score, 82);

        if (genericName.indexOf(normalizedText) === 0)
            score = Math.max(score, 74);
        else if (genericName.indexOf(normalizedText) >= 0)
            score = Math.max(score, 66);

        if (keywords.indexOf(normalizedText) >= 0)
            score = Math.max(score, 58);

        if (categories.indexOf(normalizedText) >= 0)
            score = Math.max(score, 52);

        if (comment.indexOf(normalizedText) >= 0)
            score = Math.max(score, 46);

        if (execString.indexOf(normalizedText) >= 0)
            score = Math.max(score, 42);

        return score;
    }

    function buildApps(entries, maxItems, normalizedText) {
        const normalized = [];
        const capped = Math.max(0, maxItems);
        const used = new Set();
        const favorites = favoriteSpecs();

        function tryPush(entry, displayName) {
            if (!entry || normalized.length >= capped)
                return false;

            const key = entryKey(entry);
            const name = entry.name || "";

            if (!name.length || used.has(key))
                return false;

            used.add(key);
            normalized.push(normalizeEntry(entry, displayName));
            return true;
        }

        if (normalizedText.length > 0) {
            const matches = [];

            for (let i = 0; i < entries.length; i++) {
                const entry = entries[i];
                const name = entry.name || "";

                if (!name.length)
                    continue;

                const haystack = haystackFor(entry);
                const score = scoreEntry(entry, haystack, normalizedText);

                if (score < 0)
                    continue;

                matches.push({
                    entry: entry,
                    score: score,
                    label: displayLabelForEntry(entry, haystack)
                });
            }

            matches.sort((a, b) => {
                if (b.score !== a.score)
                    return b.score - a.score;

                return (a.label || "").localeCompare(b.label || "");
            });

            for (let i = 0; i < matches.length && normalized.length < capped; i++)
                tryPush(matches[i].entry, matches[i].label);

            return normalized;
        }

        for (const favorite of favorites) {
            for (let i = 0; i < entries.length && normalized.length < capped; i++) {
                const entry = entries[i];
                const haystack = haystackFor(entry);

                if (favorite.matcher(entry, haystack) && tryPush(entry, favorite.label))
                    break;
            }
        }

        for (let i = 0; i < entries.length && normalized.length < capped; i++) {
            tryPush(entries[i]);
        }

        return normalized;
    }
}
