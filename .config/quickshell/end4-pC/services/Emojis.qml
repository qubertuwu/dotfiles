pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Emojis.
 */
Singleton {
    id: root
    property string emojiScriptPath: `${Directories.config}/hypr/hyprland/scripts/fuzzel-emoji.sh`
	property string lineBeforeData: "### DATA ###"
    property list<var> list
    readonly property var preparedEntries: list.map(a => ({
        name: Fuzzy.prepare(`${a}`),
        entry: a
    }))
    function fuzzyQuery(search: string): var {
        if (!search || search.trim() === "") {
            return root.list.slice(0, 80);
        }
        if (root.sloppySearch) {
            const results = root.list.slice(0, 100).map(str => ({
                entry: str,
                score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > (root.scoreThreshold ?? 0.2))
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function load() {
        emojiFileView.reload()
    }

    function updateEmojis(fileContent) {
        if (!fileContent) return;
        const lines = fileContent.split("\n")
        const dataIndex = lines.indexOf(root.lineBeforeData)
        const emojiLines = (dataIndex !== -1) ? lines.slice(dataIndex + 1) : lines;
        const emojis = emojiLines.filter(line => line.trim() !== "")
        root.list = emojis.map(line => line.trim())
    }

    FileView { 
        id: emojiFileView
        path: Qt.resolvedUrl(root.emojiScriptPath)
        onLoadedChanged: {
            if (emojiFileView.loaded) {
                const fileContent = emojiFileView.text()
                root.updateEmojis(fileContent)
            }
        }
    }

    Component.onCompleted: {
        if (emojiFileView.loaded) {
            root.updateEmojis(emojiFileView.text());
        } else {
            root.load();
        }
    }
}
