// Шпаргалка по клавишам (?). Любая клавиша закрывает.
import QtQuick

Rectangle {
    width: 620
    height: grid.implicitHeight + 36
    radius: Theme.radius
    color: Theme.background
    border.width: 1
    border.color: Theme.selected

    readonly property var keys: [
        ["h j k l", "move"], ["gg / G", "first / last"],
        ["Ctrl+d / Ctrl+u", "half page"], ["Enter", "apply (stays open)"],
        ["Space", "quick look"], ["f", "favorite"],
        ["r", "random from filter"], ["c", "similar colors"],
        ["s", "cycle sort"], ["e", "edit tags"],
        ["/", "search (#tag exact)"], ["Tab", "sidebar filters"],
        ["x", "clear filters"], ["T", "tag with gemma"],
        ["Quick look: h/l", "move portrait frame"], ["Quick look: 0", "auto frame"],
        ["Quick look: j/k", "next / previous"], ["q / Esc", "close"]
    ]

    Grid {
        id: grid
        anchors { fill: parent; margins: 18 }
        columns: 4
        columnSpacing: 14
        rowSpacing: 8
        Repeater {
            model: [].concat(...parent.parent.keys)
            Text {
                required property var modelData
                required property int index
                text: modelData
                color: index % 2 ? Theme.foreground : Theme.active
                font { family: Theme.font; pointSize: Theme.fontSize - 1; weight: index % 2 ? Font.Normal : Font.DemiBold }
            }
        }
    }
}
