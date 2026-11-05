// Данные и фильтры. Читает только ~/.cache/walls/view.json (его пишет binc/walls), все изменения —
// через вызовы `walls …`; view.json обновляется, и FileView подхватывает его по inotify.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: store

    readonly property string home: Quickshell.env("HOME")
    readonly property string walls: home + "/.config/binc/walls"

    property var all: []
    property string current: ""
    property var recent: []
    property var tagging: null      // прогресс разметки gemma или null
    property string applying: ""    // id обоев, которые сейчас применяются
    property int untaggedTotal: 0   // без учёта фильтров: разметка идёт по всем неразмеченным

    // Фильтры: И между группами, ИЛИ внутри
    property string scope: "all"    // all | fav | recent | untagged
    property var cats: ({})
    property var hues: ({})
    property string tone: ""        // "" | dark | light
    property string query: ""
    property string sort: "color"   // color | name | shuffle
    property int seed: 1
    property string similarTo: ""

    property var shown: []
    property var categories: []     // все категории по убыванию числа обоев
    property var counts: ({ scope: {}, cats: {}, hues: {}, tone: {} })
    property int revision: 0        // растёт при каждом пересчёте (для привязок)

    readonly property var hueNames: ["red", "orange", "yellow", "green", "teal", "blue", "purple", "pink", "mono"]
    readonly property var sortNames: ({ color: "Color", name: "Name", shuffle: "Shuffle" })
    readonly property bool filtered: scope !== "all" || Object.keys(cats).length > 0
        || Object.keys(hues).length > 0 || tone !== "" || query !== "" || similarTo !== ""

    signal updated

    FileView {
        path: store.home + "/.cache/walls/view.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()
        onLoaded: store.load(text())
    }

    // Новые файлы в папке: досчитать превью и цвета (без gemma — разметка только вручную)
    Process {
        running: true
        command: [store.walls, "index", "-q"]
    }

    function run(args) {
        Quickshell.execDetached([walls].concat(args));
    }

    function load(text) {
        let v;
        try {
            v = JSON.parse(text);
        } catch (e) {
            return; // недописанный файл — дождёмся следующего события
        }
        all = v.items || [];
        if (v.current !== current && applying === v.current)
            applying = "";
        current = v.current || "";
        recent = v.recent || [];
        tagging = v.tagging || null;
        untaggedTotal = all.filter(i => !i.tagged).length;
        const n = {};
        for (const it of all)
            for (const c of it.categories)
                n[c] = (n[c] || 0) + 1;
        categories = Object.keys(n).sort((a, b) => n[b] - n[a] || a.localeCompare(b));
        recompute();
    }

    // ---------------------------------------------------------------- фильтрация

    function tokens() {
        return query.toLowerCase().split(/\s+/).filter(t => t.length > 0);
    }

    function matchQuery(it, toks) {
        for (const t of toks) {
            if (t.startsWith("#")) {
                const tag = t.slice(1);
                if (tag && !it.tags.some(x => x.toLowerCase() === tag) && !it.categories.some(x => x === tag))
                    return false;
                continue;
            }
            const hay = (it.file + " " + it.categories.join(" ") + " " + it.tags.join(" ") + " " + it.caption).toLowerCase();
            if (!hay.includes(t))
                return false;
        }
        return true;
    }

    function matches(it, skip, toks, recentSet) {
        if (skip !== "scope") {
            if (scope === "fav" && !it.fav) return false;
            if (scope === "recent" && !recentSet[it.id]) return false;
            if (scope === "untagged" && it.tagged) return false;
        }
        if (skip !== "cats" && Object.keys(cats).length && !it.categories.some(c => cats[c])) return false;
        if (skip !== "hues" && Object.keys(hues).length && !it.hues.some(h => hues[h])) return false;
        if (skip !== "tone" && tone && it.tone !== tone) return false;
        if (toks.length && !matchQuery(it, toks)) return false;
        return true;
    }

    function hash(s) {
        let h = 2166136261;
        for (let i = 0; i < s.length; i++)
            h = Math.imul(h ^ s.charCodeAt(i), 16777619);
        return h >>> 0;
    }

    // Расстояние палитр: средний по долям ΔE до ближайшего цвета другой палитры (в обе стороны)
    function paletteDistance(a, b) {
        function half(p, q) {
            let s = 0;
            for (const x of p) {
                let best = 1e9;
                for (const y of q) {
                    const d = Math.hypot(x.lab[0] - y.lab[0], x.lab[1] - y.lab[1], x.lab[2] - y.lab[2]);
                    if (d < best) best = d;
                }
                s += x.share * best;
            }
            return s;
        }
        return half(a, b) + half(b, a);
    }

    function recompute() {
        const toks = tokens();
        const recentSet = {};
        recent.forEach((id, i) => recentSet[id] = i + 1);

        const c = { scope: { all: 0, fav: 0, recent: 0, untagged: 0 }, cats: {}, hues: {}, tone: { dark: 0, light: 0 } };
        const res = [];
        for (const it of all) {
            if (matches(it, "scope", toks, recentSet)) {
                c.scope.all++;
                if (it.fav) c.scope.fav++;
                if (recentSet[it.id]) c.scope.recent++;
                if (!it.tagged) c.scope.untagged++;
            }
            if (matches(it, "cats", toks, recentSet))
                for (const x of it.categories) c.cats[x] = (c.cats[x] || 0) + 1;
            if (matches(it, "hues", toks, recentSet))
                for (const x of it.hues) c.hues[x] = (c.hues[x] || 0) + 1;
            if (matches(it, "tone", toks, recentSet))
                c.tone[it.tone]++;
            if (matches(it, "", toks, recentSet))
                res.push(it);
        }

        const ref = similarTo ? all.find(i => i.id === similarTo) : null;
        if (ref) {
            const d = {};
            for (const it of res) d[it.id] = it.id === ref.id ? -1 : paletteDistance(ref.palette, it.palette);
            res.sort((a, b) => d[a.id] - d[b.id]);
        } else if (scope === "recent") {
            res.sort((a, b) => recentSet[a.id] - recentSet[b.id]);
        } else if (sort === "color") {
            res.sort((a, b) => a.rainbow - b.rainbow || a.lightness - b.lightness);
        } else if (sort === "shuffle") {
            const k = {};
            for (const it of res) k[it.id] = hash(it.id + seed);
            res.sort((a, b) => k[a.id] - k[b.id]);
        } else {
            res.sort((a, b) => a.file.toLowerCase().localeCompare(b.file.toLowerCase()));
        }
        counts = c;
        shown = res;
        revision++;
        updated();
    }

    // ---------------------------------------------------------------- действия

    function toggleIn(name, key) {
        const s = Object.assign({}, store[name]);
        if (s[key]) delete s[key]; else s[key] = true;
        store[name] = s;
        recompute();
    }

    function setScope(s) { scope = scope === s ? "all" : s; recompute(); }
    function setTone(t) { tone = tone === t ? "" : t; recompute(); }
    function setQuery(q) { query = q; recompute(); }
    function setSort(s) { sort = s; if (s === "shuffle") seed++; similarTo = ""; recompute(); }
    function cycleSort() { setSort(sort === "color" ? "name" : sort === "name" ? "shuffle" : "color"); }
    function similar(id) { similarTo = similarTo === id ? "" : id; recompute(); }

    function clearFilters() {
        scope = "all"; cats = {}; hues = {}; tone = ""; query = ""; similarTo = "";
        recompute();
    }

    function apply(it) {
        if (!it) return;
        applying = it.id;
        run(["apply", it.path]);
    }

    function fav(it) { if (it) run(["fav", it.id]); }

    // Тема для этих обоев: auto → light → dark → auto. Для текущих — сразу применить (binc/theme wall)
    function cycleTheme(it) {
        if (!it) return;
        const next = { auto: "light", light: "dark", dark: "auto" }[it.theme || "auto"];
        if (it.id === current)
            Quickshell.execDetached([home + "/.config/binc/theme", "wall", next]);
        else
            run(["theme", it.id, next]);
    }
    function crop(it, x) { if (it) run(["crop", it.id, x === null ? "reset" : x.toFixed(3)]); }

    function saveTags(it, categories, tags, caption) {
        run(["tags", it.id, "--categories", categories, "--tags", tags, "--caption", caption]);
    }
    function resetTags(it) { run(["tags", it.id, "--reset"]); }

    function startTagging() {
        Quickshell.execDetached(["systemd-run", "--user", "--collect", "--unit=walls-tag",
            "--description=Tag wallpapers with gemma", walls, "tag"]);
    }
    function stopTagging() {
        Quickshell.execDetached(["systemctl", "--user", "stop", "walls-tag"]);
    }
}
