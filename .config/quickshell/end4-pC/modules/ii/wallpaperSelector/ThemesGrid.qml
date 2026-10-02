import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string searchQuery: ""
    property int columns: 3
    property real previewAspectRatio: 16 / 9

    property var allThemes: []
    property var filteredThemes: []
    property int currentIndex: 0

    function moveSelection(delta) {
        if (filteredThemes.length === 0) return;
        currentIndex = Math.max(0, Math.min(filteredThemes.length - 1, currentIndex + delta));
        themesGridView.positionViewAtIndex(currentIndex, GridView.Contain);
    }

    function activateCurrent() {
        if (currentIndex >= 0 && currentIndex < filteredThemes.length) {
            const item = filteredThemes[currentIndex];
            if (item && item.name) {
                Presets.applyOnline(item.name);
                GlobalStates.wallpaperSelectorOpen = false;
            }
        }
    }

    function formatThemeName(rawName) {
        if (!rawName) return "";
        const acronyms = { "bmw": "BMW", "gtr": "GTR", "nfs": "NFS", "v2": "v2", "4k": "4K" };
        return rawName.replace(/[-_]/g, " ").split(" ").map(word => {
            const lower = word.toLowerCase();
            if (acronyms[lower]) return acronyms[lower];
            return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
        }).join(" ");
    }

    function reloadThemes() {
        let list = [];
        const home = Quickshell.env("HOME");
        const count = Presets.onlineFolderModel.count;

        for (let i = 0; i < count; ++i) {
            const fn = Presets.onlineFolderModel.get(i, "fileName") || "";
            if (!fn.endsWith(".json") || fn.startsWith(".") || fn === "tree_cache.json") continue;
            const rawName = fn.replace(".json", "");
            const previewPath = `${home}/.cache/quickshell/presets/assets/${rawName}/preview.png`;
            list.push({
                name: rawName,
                displayName: formatThemeName(rawName),
                preview: previewPath
            });
        }

        list.sort((a, b) => a.displayName.localeCompare(b.displayName));
        allThemes = list;
        filterThemes();
    }

    function filterThemes() {
        const query = (searchQuery || "").trim().toLowerCase();
        if (query.length === 0) {
            filteredThemes = allThemes;
        } else {
            filteredThemes = allThemes.filter(t => 
                t.displayName.toLowerCase().includes(query) || 
                t.name.toLowerCase().includes(query)
            );
        }
        currentIndex = Math.min(currentIndex, Math.max(0, filteredThemes.length - 1));
    }

    onSearchQueryChanged: filterThemes()

    Component.onCompleted: reloadThemes()

    Connections {
        target: Presets.onlineFolderModel
        function onCountChanged() { root.reloadThemes(); }
        function onStatusChanged() { root.reloadThemes(); }
    }

    // Grid View
    GridView {
        id: themesGridView
        anchors.fill: parent
        anchors.margins: 8
        clip: true
        interactive: true
        acceptedButtons: Qt.NoButton
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: StyledScrollBar {}

        cellWidth: width / root.columns
        cellHeight: (cellWidth - 16) / root.previewAspectRatio + 62

        model: root.filteredThemes

        delegate: Item {
            id: themeCell
            required property var modelData
            required property int index

            width: themesGridView.cellWidth
            height: themesGridView.cellHeight

            readonly property bool isSelected: themeCell.index === root.currentIndex
            readonly property bool isHovered: cardMouseArea.containsMouse

            Rectangle {
                id: cardRect
                anchors.fill: parent
                anchors.margins: 7
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: (themeCell.isSelected || themeCell.isHovered) ? 2 : 1
                border.color: (themeCell.isSelected || themeCell.isHovered)
                    ? Appearance.colors.colPrimary
                    : Appearance.colors.colLayer0Border

                scale: themeCell.isHovered ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 160 } }

                StyledRectangularShadow {
                    target: cardRect
                    visible: themeCell.isHovered
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 16:9 Full Preview Screenshot
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: (cardRect.width) / root.previewAspectRatio
                        clip: true

                        Image {
                            id: previewImg
                            anchors.fill: parent
                            source: modelData.preview ? `file://${modelData.preview}` : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            mipmap: true
                            smooth: true

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: previewImg.width
                                    height: previewImg.height
                                    radius: Appearance.rounding.normal
                                }
                            }
                        }

                        // Gradient fade at the bottom of the screenshot
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 36
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.45) }
                            }
                        }

                        // "Full Preview" badge
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 6
                            implicitHeight: 20
                            implicitWidth: badgeText.implicitWidth + 12
                            radius: 10
                            color: Qt.rgba(0, 0, 0, 0.6)

                            StyledText {
                                id: badgeText
                                anchors.centerIn: parent
                                text: "1080p Full Preview"
                                font.pixelSize: Appearance.font.pixelSize.smaller - 2
                                font.weight: Font.Medium
                                color: "#ffffff"
                            }
                        }
                    }

                    // Card Footer
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        spacing: 8

                        MaterialShapeWrappedMaterialSymbol {
                            wrappedShape: MaterialShape.Shape.Circle
                            text: "palette"
                            iconSize: Appearance.font.pixelSize.normal
                            color: themeCell.isHovered ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colSymbol: themeCell.isHovered ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: -2

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.displayName
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Theme Preset")
                                font.pixelSize: Appearance.font.pixelSize.smaller - 1
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                            }
                        }

                        RippleButton {
                            implicitHeight: 30
                            implicitWidth: 78
                            buttonRadius: height / 2
                            colBackground: themeCell.isHovered ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colPrimaryHover
                            colRipple: Appearance.colors.colPrimaryActive
                            onClicked: {
                                Presets.applyOnline(modelData.name);
                                GlobalStates.wallpaperSelectorOpen = false;
                            }
                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 3
                                MaterialSymbol {
                                    text: "check"
                                    iconSize: Appearance.font.pixelSize.small
                                    color: themeCell.isHovered ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                }
                                StyledText {
                                    text: Translation.tr("Apply")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.Bold
                                    color: themeCell.isHovered ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: cardMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = themeCell.index;
                        Presets.applyOnline(modelData.name);
                        GlobalStates.wallpaperSelectorOpen = false;
                    }
                }
            }
        }
    }

    // Empty state when filter has no results
    Item {
        anchors.centerIn: parent
        visible: root.filteredThemes.length === 0
        implicitWidth: 300
        implicitHeight: 120

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "search_off"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colSubtext
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("No themes matching query")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }
    }
}
