// Quick Look (Space): крупное превью, палитры, теги и как обои лягут на каждый монитор.
// Для портретных мониторов кадр двигается h/l (Shift — крупнее шаг) или мышью, 0 — вернуть авто.
import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: ql
    property var item: null
    property real pendingCrop: -1   // локальная позиция кадра до записи в walls
    readonly property real cropX: pendingCrop >= 0 ? pendingCrop
        : item ? (item.crop_x ?? item.attention_x) : 0.5
    readonly property bool hasPortrait: Quickshell.screens.some(s => s.height > s.width)

    color: Theme.background
    radius: Theme.radius

    onItemChanged: { commit.stop(); pendingCrop = -1; }

    function nudge(d) {
        if (!item || !hasPortrait) return;
        pendingCrop = Math.min(Math.max(cropX + d, 0), 1);
        commit.restart();
    }
    function resetCrop() {
        if (!item) return;
        commit.stop();
        pendingCrop = -1;
        Store.crop(item, null);
    }
    function flush() {
        if (commit.running) { commit.stop(); commit.triggered(); }
    }

    Timer {
        id: commit
        interval: 400
        onTriggered: if (ql.item && ql.pendingCrop >= 0) Store.crop(ql.item, ql.pendingCrop)
    }

    // ---------------------------------------------------------------- крупное превью
    ClippingRectangle {
        id: hero
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: info.left; margins: 18 }
        radius: Theme.radiusSmall
        color: "transparent"
        Image {
            id: big
            anchors.fill: parent
            source: ql.item ? "file://" + ql.item.path : ""
            sourceSize.width: 2048
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
        Image {   // пока грузится оригинал — растянутое превью
            anchors.fill: parent
            visible: big.status !== Image.Ready
            source: ql.item ? "file://" + ql.item.thumb : ""
            fillMode: Image.PreserveAspectFit
        }
    }

    // ---------------------------------------------------------------- справа: сведения
    Flickable {
        id: info
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: 18 }
        width: Math.min(360, parent.width * 0.32)
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: info.width
            spacing: 14

            Text {
                width: parent.width
                text: ql.item ? ql.item.file : ""
                wrapMode: Text.WrapAnywhere
                color: Theme.foreground
                font { family: Theme.font; pointSize: Theme.fontSize + 2; weight: Font.DemiBold }
            }
            Text {
                text: ql.item ? `${ql.item.w}×${ql.item.h} · ${ql.item.tone}`
                      + (ql.item.theme && ql.item.theme !== "auto" ? ` → ${ql.item.theme} (d)` : "")
                      + (ql.item.fav ? " · ★" : "")
                    + (ql.item.uses ? ` · used ${ql.item.uses}×` : "") : ""
                color: Theme.dim
                font { family: Theme.font; pointSize: Theme.fontSize - 1 }
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: ql.item ? ql.item.caption : ""
                wrapMode: Text.Wrap
                color: Theme.foreground
                font { family: Theme.font; pointSize: Theme.fontSize; italic: true }
            }
            Flow {   // категории и теги
                width: parent.width
                spacing: 6
                Repeater {
                    model: ql.item ? [...ql.item.categories.map(c => ({ t: c, cat: true })),
                                      ...ql.item.tags.map(t => ({ t: "#" + t, cat: false }))] : []
                    Rectangle {
                        required property var modelData
                        width: chip.implicitWidth + 16; height: 24
                        radius: Theme.radiusSmall
                        color: modelData.cat ? Theme.active : Theme.backgroundAlt
                        Text {
                            id: chip
                            anchors.centerIn: parent
                            text: parent.modelData.t
                            color: parent.modelData.cat ? Theme.background : Theme.foreground
                            font { family: Theme.font; pointSize: Theme.fontSize - 1 }
                        }
                    }
                }
            }
            Text {
                visible: ql.item && !ql.item.tagged
                text: "Not tagged yet — e to tag by hand, T for gemma"
                color: Theme.dim
                font { family: Theme.font; pointSize: Theme.fontSize - 1 }
            }

            Section { text: "wallust palette" }
            Grid {
                columns: 8
                spacing: 4
                Repeater {
                    model: ql.item ? ql.item.wallust : []
                    Rectangle {
                        required property var modelData
                        width: (col.width - 7 * 4) / 8; height: 22; radius: 4
                        color: modelData
                        border.width: 1
                        border.color: Qt.alpha(Theme.foreground, 0.15)
                    }
                }
            }

            Section { text: "dominant colors" }
            Row {   // доли доминантных цветов
                width: parent.width
                height: 12
                Repeater {
                    model: ql.item ? ql.item.palette : []
                    Rectangle {
                        required property var modelData
                        width: col.width * modelData.share
                        height: 12
                        color: modelData.hex
                    }
                }
            }

            Section { text: "on your monitors" }
            Text {
                visible: ql.hasPortrait
                text: "h/l or drag — move portrait frame · 0 — auto"
                color: Theme.dim
                font { family: Theme.font; pointSize: Theme.fontSize - 2 }
            }
            Flow {
                width: parent.width
                spacing: 12
                Repeater {
                    model: Quickshell.screens
                    MonitorPreview {
                        required property var modelData
                        screen: modelData
                        item: ql.item
                        cropX: ql.cropX
                        onDragged: x => { ql.pendingCrop = x; commit.restart(); }
                    }
                }
            }
        }
    }

    component Section: Text {
        color: Theme.dim
        font { family: Theme.font; pointSize: Theme.fontSize - 2; letterSpacing: 1; weight: Font.DemiBold }
        Component.onCompleted: text = text.toUpperCase()
    }
}
