// Круглый значок на карточке.
import QtQuick

Rectangle {
    property alias text: label.text
    property color fg: Theme.foreground
    width: 24; height: 24; radius: 12
    color: Qt.alpha(Theme.background, 0.8)
    Text {
        id: label
        anchors.centerIn: parent
        color: parent.fg
        font { family: Theme.icons; pointSize: Theme.fontSize - 1 }
    }
}
