// Сетка превью 16:9. Выбор держится по id: после пересчёта фильтров курсор остаётся на тех же обоях.
import QtQuick
import Quickshell
import Quickshell.Widgets

GridView {
    id: grid

    readonly property int columns: Math.max(2, Math.round(width / 300))
    readonly property var item: currentIndex >= 0 && currentIndex < count ? Store.shown[currentIndex] : null
    property string selectedId: ""
    signal activated(var it)
    signal peek(var it)

    cellWidth: Math.floor(width / columns)
    cellHeight: Math.round(cellWidth * 9 / 16)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    highlightMoveDuration: 120
    keyNavigationEnabled: false   // клавиши разбирает shell.qml (Vim-режимы)
    cacheBuffer: cellHeight * 4
    model: Store.shown

    onCurrentIndexChanged: if (item) selectedId = item.id

    Connections {
        target: Store
        function onUpdated() {
            const i = Store.shown.findIndex(x => x.id === grid.selectedId);
            grid.currentIndex = i >= 0 ? i : Math.min(Math.max(grid.currentIndex, 0), grid.count - 1);
        }
    }

    function moveBy(d) {
        if (count === 0) return;
        currentIndex = Math.min(Math.max(currentIndex + d, 0), count - 1);
    }
    function moveRows(r) { moveBy(r * columns); }
    function halfPage(sign) { moveRows(sign * Math.max(1, Math.floor(height / cellHeight / 2))); }

    function select(id) {
        const i = Store.shown.findIndex(x => x.id === id);
        if (i >= 0) currentIndex = i;
    }

    delegate: Item {
        id: cell
        required property var modelData
        required property int index
        readonly property bool sel: GridView.isCurrentItem
        width: grid.cellWidth
        height: grid.cellHeight

        ClippingRectangle {
            id: card
            anchors { fill: parent; margins: 6 }
            radius: Theme.radiusSmall
            color: Theme.backgroundAlt
            scale: cell.sel ? 1.0 : 0.95
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            Image {
                anchors.fill: parent
                source: "file://" + cell.modelData.thumb
                sourceSize { width: 640; height: 360 }
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: status === Image.Ready ? (cell.sel ? 1 : 0.82) : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }

            // Бейджи: текущие обои, ★, «применяется», пометка темы
            Row {
                anchors { top: parent.top; right: parent.right; margins: 8 }
                spacing: 4
                Badge { visible: cell.modelData.id === Store.applying; text: "󰔟"; fg: Theme.active }
                Badge { visible: cell.modelData.id === Store.current; text: "󰄬"; fg: Theme.active }
                Badge { visible: cell.modelData.fav; text: ""; fg: "#ffc53d" }
                // Пометка темы (d): солнце — всегда светлая, луна — всегда тёмная
                Badge { visible: cell.modelData.theme === "light" || cell.modelData.theme === "dark"
                        text: cell.modelData.theme === "light" ? "󰖨" : "󰖔"; fg: Theme.foreground }
            }
        }

        Rectangle {   // рамка выбора поверх (у ClippingRectangle рамку клипует содержимое)
            anchors.fill: card
            scale: card.scale
            radius: Theme.radiusSmall
            color: "transparent"
            border.width: cell.sel ? 2 : 0
            border.color: Theme.selected
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                grid.currentIndex = cell.index;
                if (mouse.button === Qt.RightButton) grid.peek(cell.modelData);
            }
            onDoubleClicked: grid.activated(cell.modelData)
        }
    }

    Text {
        anchors.centerIn: parent
        visible: grid.count === 0
        text: Store.all.length ? "Nothing matches — x clears filters" : "Indexing wallpapers…"
        color: Theme.dim
        font { family: Theme.font; pointSize: Theme.fontSize + 1 }
    }
}
