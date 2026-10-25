// Нижняя строка: выбранные обои (имя, размер, теги), их палитра wallust, счётчик, режим.
import QtQuick

Item {
    id: bar
    property var item: null
    height: 32

    Row {
        id: left
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter; right: right.left; rightMargin: 16 }
        spacing: 10
        clip: true

        Text {
            text: bar.item ? bar.item.file : ""
            color: Theme.foreground
            elide: Text.ElideMiddle
            width: Math.min(implicitWidth, left.width * 0.45)
            font { family: Theme.font; pointSize: Theme.fontSize; weight: Font.DemiBold }
        }
        Text {
            text: bar.item ? `${bar.item.w}×${bar.item.h}` : ""
            color: Theme.dim
            font { family: Theme.font; pointSize: Theme.fontSize - 1 }
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: bar.item ? [...bar.item.categories, ...bar.item.tags.slice(0, 6).map(t => "#" + t)].join("  ") : ""
            color: Theme.dim
            elide: Text.ElideRight
            width: Math.max(0, left.width - x)
            font { family: Theme.font; pointSize: Theme.fontSize - 1 }
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        id: right
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 14

        Row {   // палитра, в которую перекрасится система (wallust color1..7)
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: bar.item ? bar.item.wallust.slice(1, 8) : []
                Rectangle {
                    required property var modelData
                    width: 14; height: 14; radius: 4
                    color: modelData
                    border.width: 1
                    border.color: Qt.alpha(Theme.foreground, 0.15)
                }
            }
        }
        Text {
            text: (Store.similarTo ? "similar · " : "") + Store.sortNames[Store.sort]
            color: Theme.dim
            font { family: Theme.font; pointSize: Theme.fontSize - 1 }
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: `${Store.shown.length} / ${Store.all.length}`
            color: Theme.foreground
            font { family: Theme.font; pointSize: Theme.fontSize - 1 }
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: "? keys"
            color: Theme.dim
            font { family: Theme.font; pointSize: Theme.fontSize - 1 }
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
