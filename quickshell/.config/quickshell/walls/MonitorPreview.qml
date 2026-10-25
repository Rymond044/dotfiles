// Миниатюра монитора: альбомный — обои по центру (как awww crop), портретный — кадр вокруг cropX
// (так же считает walls: portrait_frame). Портретный кадр можно тащить мышью.
import QtQuick
import Quickshell
import Quickshell.Widgets

Column {
    id: mp
    property var screen
    property var item: null
    property real cropX: 0.5
    signal dragged(real x)

    readonly property bool portrait: screen.height > screen.width
    readonly property real boxH: 110
    readonly property real boxW: boxH * screen.width / screen.height
    readonly property real imgAspect: item ? item.w / item.h : 16 / 9
    spacing: 4

    ClippingRectangle {
        id: box
        width: mp.boxW
        height: mp.boxH
        radius: 4
        color: Theme.backgroundAlt
        border.width: 1
        border.color: Qt.alpha(Theme.foreground, 0.2)

        Image {
            // Высота кадра = высота картинки (как в portrait_frame), ширина — по пропорции картинки
            readonly property real fullW: mp.portrait ? box.height * mp.imgAspect : box.width
            width: mp.portrait ? fullW : box.width
            height: box.height
            x: mp.portrait ? Math.min(0, Math.max(box.width - fullW, box.width / 2 - mp.cropX * fullW)) : 0
            source: mp.item ? "file://" + mp.item.thumb : ""
            fillMode: mp.portrait ? Image.Stretch : Image.PreserveAspectCrop
            asynchronous: true
            Behavior on x { NumberAnimation { duration: 90 } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: mp.portrait
            cursorShape: enabled ? Qt.SizeHorCursor : Qt.ArrowCursor
            property real startX
            property real startCrop
            onPressed: m => { startX = m.x; startCrop = mp.cropX; }
            onPositionChanged: m => {
                const fullW = box.height * mp.imgAspect;
                mp.dragged(Math.min(1, Math.max(0, startCrop - (m.x - startX) / fullW)));
            }
        }
    }
    Text {
        text: mp.screen.name
        color: Theme.dim
        font { family: Theme.font; pointSize: Theme.fontSize - 2 }
    }
}
