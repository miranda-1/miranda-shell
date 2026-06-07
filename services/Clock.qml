pragma Singleton

import Quickshell
import QtQuick

// Serviço read-only de hora/data (Fase 5 — primeira integração real).
// Fonte: Quickshell SystemClock (nativo, evented — sem polling manual e sem
// comando externo). Precisão de minuto: dateChanged dispara a cada minuto, o
// que basta para o relógio e para detectar a virada do dia no calendário.
// NÃO escreve nada no sistema; apenas expõe strings formatadas para a UI.
Singleton {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // QDateTime exposto como Date (JS) — base para todos os formatos abaixo.
    readonly property date now: clock.date

    // Locale pt-BR para nomes de dia/mês.
    readonly property var _loc: Qt.locale("pt_BR")

    // primeira letra maiúscula (pt-BR abrevia em minúsculas: "sáb." / "junho")
    function _cap(s) {
        return s.length > 0 ? s[0].toUpperCase() + s.slice(1) : s;
    }

    // ---- EdgeLeft: relógio empilhado "21" / "40" (dois dígitos cada) ----
    readonly property string hour: (clock.hours < 10 ? "0" : "") + clock.hours
    readonly property string minute: (clock.minutes < 10 ? "0" : "") + clock.minutes

    // ---- Dashboard: relógio grande "21:06" ----
    readonly property string timeText: root.hour + ":" + root.minute

    // ---- Dashboard: data "Sáb, 7 de Junho" ----
    readonly property string dateText: {
        const wd = root._cap(root.now.toLocaleDateString(root._loc, "ddd").replace(".", ""));
        const month = root._cap(root.now.toLocaleDateString(root._loc, "MMMM"));
        return wd + ", " + root.now.getDate() + " de " + month;
    }

    // ---- CalendarCard: mês corrente real ----
    readonly property int currentYear: root.now.getFullYear()
    readonly property int currentMonth: root.now.getMonth() + 1   // 1–12
    readonly property int currentDay: root.now.getDate()          // 1–31
    readonly property string monthName: root._cap(root.now.toLocaleDateString(root._loc, "MMMM"))

    // Dias no mês: dia 0 do mês seguinte = último dia do mês atual.
    readonly property int daysInMonth: new Date(root.currentYear, root.currentMonth, 0).getDate()

    // Índice do dia 1 numa semana que começa na SEGUNDA (0=Seg … 6=Dom).
    // getDay() é 0=Dom … 6=Sáb; (+6)%7 desloca para a base segunda.
    // Vale também como nº de células vazias antes do dia 1.
    readonly property int firstWeekday: {
        const first = new Date(root.currentYear, root.currentMonth - 1, 1);
        return (first.getDay() + 6) % 7;
    }

    // Grade pronta: células vazias antes do dia 1, dias 1..daysInMonth, e
    // preenchimento vazio até completar a última linha (múltiplo de 7).
    // Cada célula: { day: int (0 = vazio), empty: bool }.
    readonly property var calendarCells: {
        const cells = [];
        for (let i = 0; i < root.firstWeekday; i++)
            cells.push({ day: 0, empty: true });
        for (let d = 1; d <= root.daysInMonth; d++)
            cells.push({ day: d, empty: false });
        while (cells.length % 7 !== 0)
            cells.push({ day: 0, empty: true });
        return cells;
    }
}
