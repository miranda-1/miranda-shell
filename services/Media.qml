pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Serviço de mídia baseado em MPRIS. Prioriza players em Playing, cai para
// Paused quando não houver player tocando e ignora sessões Stopped/vazias.
// Ações mutáveis, quando suportadas pela API typed do Quickshell, ficam
// centralizadas aqui.
Singleton {
    id: root

    readonly property var players: root._playerValues(Mpris.players)
    readonly property var candidatePlayers: {
        const list = [];

        for (let i = 0; i < root.players.length; i++) {
            const player = root.players[i];
            if (root._isPlayerCandidate(player))
                list.push(player);
        }

        return list;
    }

    readonly property var player: {
        let selected = null;
        let selectedScore = -1;

        for (let i = 0; i < root.candidatePlayers.length; i++) {
            const candidate = root.candidatePlayers[i];
            const score = root._playerScore(candidate);

            if (!selected || score > selectedScore) {
                selected = candidate;
                selectedScore = score;
            }
        }

        return selected;
    }

    readonly property bool available: !!root.player
    readonly property int playerCount: root.candidatePlayers.length
    readonly property int detectedPlayerCount: root.players.length

    readonly property int playbackState: root.available ? root.player.playbackState : MprisPlaybackState.Stopped
    readonly property string playbackStatus: MprisPlaybackState.toString(root.playbackState)
    readonly property bool isPlaying: root.playbackState === MprisPlaybackState.Playing
    readonly property bool isPaused: root.playbackState === MprisPlaybackState.Paused

    readonly property string activePlayerName: root._playerName(root.player)
    readonly property string title: root._playerTitle(root.player)
    readonly property string artist: root._playerArtist(root.player)
    readonly property string album: root._playerAlbum(root.player)
    readonly property string artUrl: root._safeString(root.available ? root.player.trackArtUrl : "", "")
    readonly property string subtitle: root._playerSubtitle(root.player)
    readonly property string statusText: {
        if (root.isPlaying)
            return "Tocando";
        if (root.isPaused)
            return "Pausado";
        return "Nada tocando";
    }
    readonly property string displayTitle: {
        if (!root.available)
            return "Nada tocando";
        if (root.title)
            return root.title;
        return "Sem título disponível";
    }
    readonly property string displaySubtitle: {
        if (!root.available)
            return "Sem mídia ativa";
        if (root.subtitle)
            return root.subtitle;
        return "Sem detalhes de mídia";
    }

    readonly property bool canPlayPause: {
        if (!root.available || !root.player)
            return false;

        return !!(root.player.canTogglePlaying
            || (root.isPlaying && root.player.canPause)
            || (root.isPaused && root.player.canPlay));
    }
    readonly property bool canNext: root.available && !!root.player.canGoNext
    readonly property bool canPrevious: root.available && !!root.player.canGoPrevious

    readonly property real length: root.available && root.player.lengthSupported ? root.player.length : 0
    readonly property real position: root.available && root.player.positionSupported ? root.player.position : 0
    readonly property real progress: root.length > 0 ? Math.max(0, Math.min(1, root.position / root.length)) : 0

    Timer {
        running: root.available && root.isPlaying && root.player.positionSupported
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    function playPause() {
        if (!root.available || !root.player)
            return false;

        if (root.player.canTogglePlaying) {
            root.player.togglePlaying();
            return true;
        }

        if (root.isPlaying && root.player.canPause) {
            root.player.pause();
            return true;
        }

        if (root.isPaused && root.player.canPlay) {
            root.player.play();
            return true;
        }

        return false;
    }

    function next() {
        if (!root.available || !root.player || !root.player.canGoNext)
            return false;

        root.player.next();
        return true;
    }

    function previous() {
        if (!root.available || !root.player || !root.player.canGoPrevious)
            return false;

        root.player.previous();
        return true;
    }

    function _fmt(sec) {
        if (!sec || sec < 0)
            return "0:00";

        const total = Math.floor(sec);
        const s = total % 60;
        const m = Math.floor(total / 60) % 60;
        const h = Math.floor(total / 3600);
        const pad = (n) => (n < 10 ? "0" : "") + n;

        if (h > 0)
            return h + ":" + pad(m) + ":" + pad(s);
        return m + ":" + pad(s);
    }

    readonly property string positionText: root._fmt(root.position)
    readonly property string lengthText: root._fmt(root.length)

    function _playerValues(model) {
        if (!model || !model.values || !model.values.slice)
            return [];

        return model.values.slice();
    }

    function _playerPlaybackState(player) {
        return player ? player.playbackState : MprisPlaybackState.Stopped;
    }

    function _isPlayerCandidate(player) {
        if (!player)
            return false;

        const state = root._playerPlaybackState(player);
        return state === MprisPlaybackState.Playing || state === MprisPlaybackState.Paused;
    }

    function _playerScore(player) {
        if (!player)
            return -1;

        let score = 0;
        const state = root._playerPlaybackState(player);

        if (state === MprisPlaybackState.Playing)
            score += 1000;
        else if (state === MprisPlaybackState.Paused)
            score += 500;

        if (root._playerTitle(player))
            score += 120;
        if (root._playerArtist(player))
            score += 60;
        if (root._playerAlbum(player))
            score += 30;
        if (root._safeString(player.trackArtUrl, ""))
            score += 20;
        if (player.positionSupported)
            score += 10;
        if (player.lengthSupported && player.length > 0)
            score += 10;
        if (player.canControl)
            score += 5;
        if (root._playerName(player))
            score += 5;

        const metadata = player.metadata;
        if (metadata)
            score += Math.min(20, Object.keys(metadata).length);

        return score;
    }

    function _playerTitle(player) {
        return root._safeString(player && player.trackTitle ? player.trackTitle : "", "");
    }

    function _playerArtist(player) {
        return root._safeString(player && player.trackArtist ? player.trackArtist : "", "");
    }

    function _playerAlbum(player) {
        return root._safeString(player && player.trackAlbum ? player.trackAlbum : "", "");
    }

    function _playerName(player) {
        if (!player)
            return "";

        const identity = root._safeString(player.identity, "");
        if (identity)
            return identity;

        const desktopEntry = root._safeString(player.desktopEntry, "");
        if (desktopEntry)
            return desktopEntry;

        const dbusName = root._safeString(player.dbusName, "");
        if (!dbusName)
            return "";

        const parts = dbusName.split(".");
        for (let i = parts.length - 1; i >= 0; i--) {
            const part = root._safeString(parts[i], "");
            if (!part || part === "instance" || part.indexOf("instance") === 0)
                continue;

            return part.charAt(0).toUpperCase() + part.slice(1);
        }

        return dbusName;
    }

    function _playerSubtitle(player) {
        const artist = root._playerArtist(player);
        const album = root._playerAlbum(player);

        if (artist && album)
            return artist + " \u2014 " + album;
        if (artist)
            return artist;
        if (album)
            return album;

        return "";
    }

    function _safeString(value, fallback) {
        if (value === undefined || value === null)
            return fallback;

        const text = String(value).trim();
        return text.length > 0 ? text : fallback;
    }
}
