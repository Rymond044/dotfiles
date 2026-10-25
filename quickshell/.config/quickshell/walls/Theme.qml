// Цвета и шрифты в стиле control center (rofi/cc/cc.rasi): палитра wallust, перечитывается
// после каждой смены обоев (~/.cache/wallust/quickshell.json ← wallust/templates/quickshell.json.j2).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    property color background: "#131718"
    property color backgroundAlt: "#3a3e40"
    property color foreground: "#f2faff"
    property color selected: "#8090a5"
    property color active: "#039cc5"
    property color urgent: "#8090a5"

    // В CC фон {{background}}CC, но на весь экран сквозь 0.8 читается текст окон — плотнее
    readonly property color panel: Qt.alpha(background, 0.94)
    readonly property color dim: Qt.alpha(foreground, 0.55)

    readonly property string font: "system-ui"
    readonly property string icons: "CaskaydiaCove Nerd Font"
    readonly property int fontSize: 11
    readonly property int radius: 12
    readonly property int radiusSmall: 8

    // Сватчи корзин оттенков (как в walls: HUES)
    readonly property var hueColors: ({
        red: "#e5484d", orange: "#f76b15", yellow: "#ffc53d", green: "#46a758",
        teal: "#12a594", blue: "#3e63dd", purple: "#8e4ec6", pink: "#d6409f", mono: "#8b8d98"
    })

    FileView {
        path: Quickshell.env("HOME") + "/.cache/wallust/quickshell.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text());
                for (const k of ["background", "backgroundAlt", "foreground", "selected", "active", "urgent"])
                    if (c[k]) theme[k] = c[k];
            } catch (e) {
                console.warn("walls: theme", e);
            }
        }
    }
}
