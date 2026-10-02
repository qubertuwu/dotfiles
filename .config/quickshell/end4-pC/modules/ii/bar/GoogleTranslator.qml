pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

MouseArea {
    id: root
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    property bool isOpen: GlobalStates.translatorOpen

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    implicitWidth: vertical ? 32 : (contentRow.implicitWidth + (root.isMaterial ? 8 : 12))
    implicitHeight: vertical ? (contentRow.implicitHeight + 8) : Appearance.sizes.barHeight

    onClicked: {
        GlobalStates.translatorOpen = !GlobalStates.translatorOpen;
    }

    Rectangle {
        id: bgPill
        anchors.centerIn: parent
        width: root.vertical ? 28 : (contentRow.implicitWidth + 10)
        height: root.vertical ? (contentRow.implicitHeight + 6) : 26
        radius: Appearance.rounding.full
        color: root.isOpen
            ? Appearance.colors.colSecondaryContainer
            : (root.containsMouse
                ? Appearance.colors.colLayer1Hover
                : (root.isMaterial ? Appearance.colors.colPrimaryContainer : "transparent"))

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                text: "g_translate"
                iconSize: 17
                color: root.isOpen
                    ? Appearance.colors.colOnSecondaryContainer
                    : (root.containsMouse
                        ? Appearance.colors.colPrimary
                        : Appearance.colors.colOnLayer0)
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                visible: !root.vertical
                text: (GlobalStates.translatorSourceLang || "en").toUpperCase() + "→" + (GlobalStates.translatorTargetLang || "ru").toUpperCase()
                font.pixelSize: 11
                font.weight: Font.Bold
                color: root.isOpen
                    ? Appearance.colors.colOnSecondaryContainer
                    : (root.containsMouse
                        ? Appearance.colors.colPrimary
                        : Appearance.colors.colOnLayer0)
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
