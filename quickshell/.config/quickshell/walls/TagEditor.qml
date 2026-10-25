// Правка тегов (e): категории и теги через запятую, описание. Tab — следующее поле,
// Enter — сохранить, Ctrl+R — вернуть теги gemma, Esc — отмена.
import QtQuick

Rectangle {
    id: ed
    property var item: null
    signal done

    width: 560
    height: col.implicitHeight + 36
    radius: Theme.radius
    color: Theme.background
    border.width: 1
    border.color: Theme.selected

    function open(it) {
        item = it;
        cats.input.text = it.categories.join(", ");
        tags.input.text = it.tags.join(", ");
        caption.input.text = it.caption;
        cats.input.forceActiveFocus();
    }
    function save() {
        Store.saveTags(item, cats.input.text, tags.input.text, caption.input.text);
        done();
    }

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape) { done(); e.accepted = true; }
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { save(); e.accepted = true; }
        else if (e.key === Qt.Key_R && (e.modifiers & Qt.ControlModifier)) { Store.resetTags(item); done(); e.accepted = true; }
    }

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 10

        Text {
            text: "Edit tags"
            color: Theme.foreground
            font { family: Theme.font; pointSize: Theme.fontSize + 1; weight: Font.DemiBold }
        }
        Field { id: cats; label: "Categories"; KeyNavigation.tab: tags.input }
        Field { id: tags; label: "Tags"; KeyNavigation.tab: caption.input }
        Field { id: caption; label: "Caption"; KeyNavigation.tab: cats.input }
        Text {
            text: "Tab next field · Enter save · Ctrl+R reset to gemma · Esc cancel"
            color: Theme.dim
            font { family: Theme.font; pointSize: Theme.fontSize - 2 }
        }
    }

    component Field: Rectangle {
        property alias label: lbl.text
        property alias input: inp
        width: col.width
        height: 34
        radius: Theme.radiusSmall
        color: Theme.backgroundAlt
        border.width: inp.activeFocus ? 1 : 0
        border.color: Theme.selected
        Text {
            id: lbl
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            width: 80
            color: Theme.dim
            font { family: Theme.font; pointSize: Theme.fontSize - 1 }
        }
        TextInput {
            id: inp
            anchors { left: lbl.right; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            color: Theme.foreground
            selectionColor: Theme.selected
            selectedTextColor: Theme.background
            clip: true
            font { family: Theme.font; pointSize: Theme.fontSize }
        }
    }
}
