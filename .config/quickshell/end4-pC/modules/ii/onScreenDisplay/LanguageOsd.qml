import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    property string displayCode: "EN"
    property string fullLanguageName: "English"
    property bool osdVisible: false
    property bool readyForEvents: false

    function updateLayout(rawName) {
        if (!rawName || typeof rawName !== "string") return;

        let code = "EN";
        let fullName = "English";
        const lower = rawName.toLowerCase();

        if (lower.indexOf("rus") !== -1 || lower.indexOf("ru") !== -1) {
            code = "RU";
            fullName = "Русский";
        } else if (lower.indexOf("eng") !== -1 || lower.indexOf("us") !== -1 || lower.indexOf("en") !== -1) {
            code = "EN";
            fullName = "English";
        } else {
            code = rawName.substring(0, 2).toUpperCase();
            fullName = rawName;
        }

        if (!root.readyForEvents) {
            root.displayCode = code;
            root.fullLanguageName = fullName;
            return;
        }

        if (code === root.displayCode && root.osdVisible) {
            hideTimer.restart();
            return;
        }

        root.displayCode = code;
        root.fullLanguageName = fullName;
        root.osdVisible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1200
        repeat: false
        onTriggered: {
            root.osdVisible = false;
        }
    }

    Timer {
        id: startupGraceTimer
        interval: 800
        running: true
        repeat: false
        onTriggered: {
            root.readyForEvents = true;
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                const data = event.data || "";
                const commaIdx = data.indexOf(",");
                if (commaIdx !== -1) {
                    const layoutName = data.substring(commaIdx + 1).trim();
                    root.updateLayout(layoutName);
                }
            }
        }
    }

    Connections {
        target: HyprlandXkb
        function onCurrentLayoutNameChanged() {
            if (HyprlandXkb.currentLayoutName) {
                root.updateLayout(HyprlandXkb.currentLayoutName);
            }
        }
    }

    Component.onCompleted: {
        if (HyprlandXkb.currentLayoutName) {
            root.updateLayout(HyprlandXkb.currentLayoutName);
        }
    }

    PanelWindow {
        id: osdWindow
        screen: Quickshell.screens.find(s => s.name === (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")) || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

        WlrLayershell.namespace: "quickshell:languageOsd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        mask: Region {}
        color: "transparent"

        anchors {
            bottom: true
        }
        margins {
            bottom: 65
        }

        implicitWidth: osdContainer.implicitWidth + 32
        implicitHeight: osdContainer.implicitHeight + 32

        visible: osdContainer.opacity > 0.01

        Item {
            id: osdContainer
            anchors.centerIn: parent
            implicitWidth: pillRect.implicitWidth
            implicitHeight: pillRect.implicitHeight

            opacity: root.osdVisible ? 1.0 : 0.0
            y: root.osdVisible ? 0 : 12
            scale: root.osdVisible ? 1.0 : 0.94

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
            Behavior on y {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: pillRect
                color: Qt.rgba(0.08, 0.09, 0.13, 0.72)
                radius: 23
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.18)

                implicitWidth: contentRow.implicitWidth + 36
                implicitHeight: 46

                RowLayout {
                    id: contentRow
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.22)
                        Layout.alignment: Qt.AlignVCenter

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "language"
                            iconSize: 17
                            color: Appearance.colors.colPrimary
                        }
                    }

                    StyledText {
                        id: codeText
                        text: root.displayCode
                        font.pixelSize: 18
                        font.bold: true
                        font.letterSpacing: 1.2
                        color: Appearance.colors.colOnLayer0
                        animateChange: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 14
                        color: Qt.rgba(1, 1, 1, 0.22)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    StyledText {
                        id: nameText
                        text: root.fullLanguageName
                        font.pixelSize: 13
                        color: Appearance.colors.colOnLayer0
                        opacity: 0.85
                        animateChange: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
