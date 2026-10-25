// Строка поиска в стиле inputbar из CC: плашка-prompt цвета active + поле ввода.
import QtQuick

Item {
    id: field
    property alias input: input
    signal accepted   // Enter / ↓ / Tab — вернуться в сетку, запрос остаётся
    signal cancelled  // Esc — сбросить запрос и вернуться
    height: 36

    Rectangle {
        id: prompt
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 36
        radius: Theme.radiusSmall
        color: Theme.active
        Text {
            anchors.centerIn: parent
            text: "󰍉"
            color: Theme.background
            font { family: Theme.icons; pointSize: Theme.fontSize + 1 }
        }
    }

    TextInput {
        id: input
        anchors { left: prompt.right; leftMargin: 10; right: parent.right; verticalCenter: parent.verticalCenter }
        color: Theme.foreground
        selectionColor: Theme.selected
        selectedTextColor: Theme.background
        font { family: Theme.font; pointSize: Theme.fontSize }
        clip: true
        onTextEdited: Store.setQuery(text)
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                text = "";
                Store.setQuery("");
                field.cancelled();
            } else if ([Qt.Key_Return, Qt.Key_Enter, Qt.Key_Down, Qt.Key_Tab].includes(e.key)) {
                field.accepted();
            } else {
                return;
            }
            e.accepted = true;
        }

        Text {
            visible: !input.text && !input.activeFocus
            text: "/  search, #tag"
            color: Qt.alpha(Theme.foreground, 0.35)
            font: input.font
        }
    }
}
