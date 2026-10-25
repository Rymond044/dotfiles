// Сайдбар: поиск, область (All/Favorites/Recent/Untagged), категории, цвета, тон, сортировка.
// Плоский список пунктов — j/k ходят по всем подряд, Space/Enter переключает.
import QtQuick
import Quickshell

Item {
    id: side

    property bool active: false     // клавиатурный фокус в сайдбаре
    property int cursor: 1
    // Курсор держится за пункт, а не за номер строки: при пересборке списка (появился/пропал пункт
    // выше) он остаётся на том же пункте, даже если тот съехал
    property string cursorKey: "scope:all"
    property alias search: search
    readonly property var entries: build(Store.revision)

    function build(_rev) {
        const e = [];
        const c = Store.counts;
        e.push({ kind: "header", label: "Library" });
        e.push({ kind: "scope", value: "all", icon: "󰸉", label: "All", count: c.scope.all, on: Store.scope === "all" });
        e.push({ kind: "scope", value: "fav", icon: "", label: "Favorites", count: c.scope.fav, on: Store.scope === "fav" });
        e.push({ kind: "scope", value: "recent", icon: "󰋚", label: "Recent", count: c.scope.recent, on: Store.scope === "recent" });
        e.push({ kind: "scope", value: "untagged", icon: "󰓻", label: "Untagged", count: c.scope.untagged, on: Store.scope === "untagged" });
        if (Store.tagging)
            e.push({ kind: "tagging", icon: "󰔟", label: `Tagging ${Store.tagging.done}/${Store.tagging.total}`, count: "stop" });
        else if (Store.untaggedTotal > 0)
            e.push({ kind: "tagging", icon: "󱚤", label: "Tag with gemma", count: "T" });

        if (Store.categories.length) {
            e.push({ kind: "header", label: "Categories" });
            for (const k of Store.categories)
                e.push({ kind: "cat", value: k, label: k, count: c.cats[k] || 0, on: !!Store.cats[k] });
        }
        e.push({ kind: "header", label: "Colors" });
        for (const k of Store.hueNames)
            e.push({ kind: "hue", value: k, label: k, count: c.hues[k] || 0, on: !!Store.hues[k] });
        e.push({ kind: "tone", value: "dark", icon: "󰖔", label: "dark", count: c.tone.dark, on: Store.tone === "dark" });
        e.push({ kind: "tone", value: "light", icon: "󰖨", label: "light", count: c.tone.light, on: Store.tone === "light" });

        e.push({ kind: "header", label: "Sort" + (Store.similarTo ? " · similar" : "") });
        for (const k of ["color", "name", "shuffle"])
            e.push({ kind: "sort", value: k, icon: k === "color" ? "󰸌" : k === "name" ? "󰈍" : "󰒝",
                     label: Store.sortNames[k], on: Store.sort === k && !Store.similarTo });
        return e;
    }

    function keyOf(e) {
        return e ? e.kind + ":" + (e.value ?? "") : "";
    }

    function setCursor(i) {
        cursor = i;
        cursorKey = keyOf(entries[i]);
        list.positionViewAtIndex(cursor, ListView.Contain);
    }

    function selectable(i) {
        return i >= 0 && i < entries.length && entries[i].kind !== "header";
    }

    function move(d) {
        let i = cursor + d;
        while (i >= 0 && i < entries.length && !selectable(i)) i += d;
        if (selectable(i)) setCursor(i);
    }

    function activate(i) {
        const e = entries[i === undefined ? cursor : i];
        if (!e) return;
        switch (e.kind) {
        case "scope": Store.setScope(e.value); break;
        case "cat": Store.toggleIn("cats", e.value); break;
        case "hue": Store.toggleIn("hues", e.value); break;
        case "tone": Store.setTone(e.value); break;
        case "sort": Store.setSort(e.value); break;
        case "tagging": Store.tagging ? Store.stopTagging() : Store.startTagging(); break;
        }
    }

    onEntriesChanged: {
        const i = entries.findIndex(e => keyOf(e) === cursorKey);
        if (i >= 0) {
            cursor = i;
            list.positionViewAtIndex(cursor, ListView.Contain);
        } else if (!selectable(cursor)) {
            move(cursor >= entries.length ? -1 : 1);   // сам пункт исчез — ближайший соседний
        }
    }

    SearchField {
        id: search
        anchors { top: parent.top; left: parent.left; right: parent.right }
    }

    ListView {
        id: list
        anchors { top: search.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: side.entries

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool header: modelData.kind === "header"
            readonly property bool cur: side.active && side.cursor === index
            width: ListView.view.width
            height: header ? 30 : 28

            Text {
                visible: row.header
                anchors { left: parent.left; leftMargin: 10; bottom: parent.bottom; bottomMargin: 4 }
                text: row.modelData.label.toUpperCase()
                color: Theme.dim
                font { family: Theme.font; pointSize: Theme.fontSize - 2; letterSpacing: 1; weight: Font.DemiBold }
            }

            Rectangle {
                visible: !row.header
                anchors.fill: parent
                radius: Theme.radiusSmall
                color: row.cur ? Theme.selected : row.modelData.on ? Qt.alpha(Theme.selected, 0.25) : "transparent"
                Behavior on color { ColorAnimation { duration: 90 } }

                Rectangle {   // сватч цвета
                    id: swatch
                    visible: row.modelData.kind === "hue"
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    width: 12; height: 12; radius: 6
                    color: Theme.hueColors[row.modelData.value] ?? "transparent"
                    border.width: row.modelData.on ? 2 : 0
                    border.color: Theme.foreground
                }
                Text {
                    id: icon
                    visible: row.modelData.kind !== "hue"
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    width: 16
                    horizontalAlignment: Text.AlignHCenter
                    text: row.modelData.icon ?? (row.modelData.on ? "󰄵" : "󰄱")
                    color: row.cur ? Theme.background : row.modelData.on ? Theme.active : Theme.dim
                    font { family: Theme.icons; pointSize: Theme.fontSize }
                }
                Text {
                    anchors { left: parent.left; leftMargin: 34; right: count.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    text: row.modelData.label
                    elide: Text.ElideRight
                    color: row.cur ? Theme.background : Theme.foreground
                    font { family: Theme.font; pointSize: Theme.fontSize; weight: row.modelData.on ? Font.DemiBold : Font.Normal }
                }
                Text {
                    id: count
                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    text: row.modelData.count ?? ""
                    color: row.cur ? Theme.background : Theme.dim
                    font { family: Theme.font; pointSize: Theme.fontSize - 1 }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { side.setCursor(row.index); side.activate(row.index); }
                }
            }
        }
    }
}
