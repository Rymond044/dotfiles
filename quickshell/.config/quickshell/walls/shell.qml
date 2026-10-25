// Выбиралка обоев (задача 4). Запуск из control center: `qs -c walls -n -d`, процесс живёт,
// пока открыто окно (холодный старт ~0,1 с). Данные — binc/walls, см. его docstring.
// Клавиши — Vim-режимы: grid | search | sidebar | look | edit | help.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    PanelWindow {
        id: win

        // WALLS_SCREEN — открыть на конкретном мониторе (для проверок)
        screen: Quickshell.screens.find(s => s.name === (Quickshell.env("WALLS_SCREEN") ?? Hyprland.focusedMonitor?.name)) ?? Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "walls"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"

        property string mode: "grid"
        property bool pendingG: false

        function setMode(m) {
            if (mode === "look" && m !== "look") look.flush();
            mode = m;
            side.active = m === "sidebar";
            if (m === "search") side.search.input.forceActiveFocus();
            else if (m !== "edit") keys.forceActiveFocus();
        }

        function randomFromFilter() {
            if (grid.count < 2) return;
            let i;
            do i = Math.floor(Math.random() * grid.count); while (i === grid.currentIndex);
            grid.currentIndex = i;
            Store.apply(grid.item);
        }

        // Затемнение под окном; клик мимо окна закрывает
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha("#000000", 0.35)
            opacity: panel.opacity
            MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
        }

        Rectangle {
            id: panel
            anchors { fill: parent; margins: win.width > 1600 ? 64 : 32 }
            color: Theme.panel
            radius: Theme.radius
            border.width: 1
            border.color: Theme.selected

            opacity: 0
            scale: 0.98
            Component.onCompleted: { opacity = 1; scale = 1; }
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent }   // клики по окну не закрывают его

            Sidebar {
                id: side
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 18 }
                width: win.width > 1300 ? 240 : 200
            }
            Connections {
                target: side.search
                function onAccepted() { win.setMode("grid"); }
                function onCancelled() { win.setMode("grid"); }
            }

            WallGrid {
                id: grid
                anchors { left: side.right; leftMargin: 12; right: parent.right; rightMargin: 12; top: parent.top; topMargin: 12; bottom: status.top }
                onActivated: it => Store.apply(it)
                onPeek: it => win.setMode("look")
            }

            StatusBar {
                id: status
                anchors { left: side.right; leftMargin: 12; right: parent.right; rightMargin: 12; bottom: parent.bottom; bottomMargin: 10 }
                item: grid.item
            }

            QuickLook {
                id: look
                anchors.fill: parent
                visible: win.mode === "look"
                item: grid.item
            }

            Rectangle {   // подложка под модальные окна
                anchors.fill: parent
                radius: Theme.radius
                color: Qt.alpha(Theme.background, 0.6)
                visible: win.mode === "edit" || win.mode === "help"
            }
            TagEditor {
                id: editor
                anchors.centerIn: parent
                visible: win.mode === "edit"
                onDone: win.setMode("grid")
            }
            Help {
                anchors.centerIn: parent
                visible: win.mode === "help"
            }
        }

        // ---------------------------------------------------------------- клавиши
        Item {
            id: keys
            focus: true
            Component.onCompleted: {
                forceActiveFocus();
                // Для скриншотов без клавиатуры: WALLS_DEBUG_MODE=look|help|sidebar|search
                const m = Quickshell.env("WALLS_DEBUG_MODE");
                if (m) Qt.callLater(() => win.setMode(m));
            }

            Keys.onPressed: e => {
                const k = e.key, ctrl = e.modifiers & Qt.ControlModifier, shift = e.modifiers & Qt.ShiftModifier;
                const it = grid.item;
                let handled = true;

                if (win.mode === "help") {
                    win.setMode("grid");
                } else if (win.mode === "look") {
                    if (k === Qt.Key_H || k === Qt.Key_Left) look.nudge(shift ? -0.1 : -0.02);
                    else if (k === Qt.Key_L || k === Qt.Key_Right) look.nudge(shift ? 0.1 : 0.02);
                    else if (k === Qt.Key_0) look.resetCrop();
                    else if (k === Qt.Key_J || k === Qt.Key_Down) { look.flush(); grid.moveBy(1); }
                    else if (k === Qt.Key_K || k === Qt.Key_Up) { look.flush(); grid.moveBy(-1); }
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter) { look.flush(); Store.apply(it); }
                    else if (k === Qt.Key_F) Store.fav(it);
                    else if (k === Qt.Key_E && it) { look.flush(); win.setMode("edit"); editor.open(it); }
                    else if ([Qt.Key_Space, Qt.Key_Escape, Qt.Key_Q].includes(k)) win.setMode("grid");
                    else handled = false;
                } else if (win.mode === "sidebar") {
                    if (k === Qt.Key_J || k === Qt.Key_Down) side.move(1);
                    else if (k === Qt.Key_K || k === Qt.Key_Up) side.move(-1);
                    else if ([Qt.Key_Space, Qt.Key_Return, Qt.Key_Enter].includes(k)) side.activate();
                    else if ([Qt.Key_L, Qt.Key_H, Qt.Key_Tab, Qt.Key_Backtab, Qt.Key_Escape, Qt.Key_Right].includes(k)) win.setMode("grid");
                    else if (k === Qt.Key_X) Store.clearFilters();
                    else if (k === Qt.Key_Slash) win.setMode("search");
                    else if (k === Qt.Key_Q) Qt.quit();
                    else handled = false;
                } else {   // grid
                    if (win.pendingG) {
                        win.pendingG = false;
                        if (k === Qt.Key_G && !shift) { grid.currentIndex = 0; e.accepted = true; return; }
                    }
                    if (ctrl && k === Qt.Key_D) grid.halfPage(1);
                    else if (ctrl && k === Qt.Key_U) grid.halfPage(-1);
                    else if (k === Qt.Key_H || k === Qt.Key_Left) grid.moveBy(-1);
                    else if (k === Qt.Key_L || k === Qt.Key_Right) grid.moveBy(1);
                    else if (k === Qt.Key_J || k === Qt.Key_Down) grid.moveRows(1);
                    else if (k === Qt.Key_K || k === Qt.Key_Up) grid.moveRows(-1);
                    else if (k === Qt.Key_G && shift) grid.currentIndex = grid.count - 1;
                    else if (k === Qt.Key_G) win.pendingG = true;
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter) Store.apply(it);
                    else if (k === Qt.Key_Space && it) win.setMode("look");
                    else if (k === Qt.Key_F) Store.fav(it);
                    else if (k === Qt.Key_R) win.randomFromFilter();
                    else if (k === Qt.Key_C && it) Store.similar(it.id);
                    else if (k === Qt.Key_S) Store.cycleSort();
                    else if (k === Qt.Key_E && it) { win.setMode("edit"); editor.open(it); }
                    else if (k === Qt.Key_X) Store.clearFilters();
                    else if (k === Qt.Key_T && shift) Store.tagging ? Store.stopTagging() : Store.startTagging();
                    else if (k === Qt.Key_Slash) win.setMode("search");
                    else if (k === Qt.Key_Tab) win.setMode("sidebar");
                    else if (k === Qt.Key_Question) win.setMode("help");
                    else if (k === Qt.Key_Q || k === Qt.Key_Escape) Qt.quit();
                    else handled = false;
                }
                e.accepted = handled;
            }
        }
    }
}
