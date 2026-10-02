pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Scope {
    id: root

    readonly property real cardWidth: 360
    readonly property bool barVertical: Config.options.bar.vertical
    readonly property string barEdge: {
        if (!barVertical) return Config.options.bar.bottom ? "bottom" : "top"
        return Config.options.bar.bottom ? "right" : "left"
    }
    readonly property real barThickness: barVertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight
    readonly property real gap: Config.options.bar.cornerStyle === 3 ? Appearance.sizes.hyprlandGapsOut : 0
    readonly property bool cornerStyleReducesGap: Config.options.bar.cornerStyle === 1 || Config.options.bar.cornerStyle === 2

    property var today: new Date()
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.today = new Date()
    }

    Loader {
        id: popupLoader
        active: GlobalStates.clockPopupOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true
            screen: Quickshell.screens.find(s => s.name === WM.focusedMonitor?.name) ?? Quickshell.screens[0]

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.namespace: "quickshell:clockPopup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            onVisibleChanged: {
                if (visible) {
                    Qt.callLater(() => {
                        cardBackground.forceActiveFocus()
                    })
                }
            }

            // Click outside card closes popup
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    GlobalStates.clockPopupOpen = false
                }
            }

            StyledRectangularShadow {
                target: cardBackground
            }

            Rectangle {
                id: cardBackground
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: {
                    if (!root.barVertical && root.barEdge === "top")
                        return root.barThickness + (root.cornerStyleReducesGap ? -root.gap - 6 : root.gap) + 6
                    return Appearance.sizes.hyprlandGapsOut + 8
                }
                width: root.cardWidth
                implicitHeight: contentLayout.implicitHeight + 28
                radius: Appearance.rounding.normal + 4
                focus: true

                // Consume clicks inside the card
                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.clockPopupOpen = false
                        event.accepted = true
                    }
                }
                color: Appearance.colors.colLayer1Base
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    id: contentLayout
                    anchors.centerIn: parent
                    width: root.cardWidth - 28
                    spacing: 10

                    // Row: Month Year + Current Time
                    RowLayout {
                        Layout.fillWidth: true

                        Row {
                            spacing: 4
                            StyledText {
                                text: Qt.locale().toString(root.today, "MMMM")
                                font.pixelSize: Appearance.font.pixelSize.huge
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: Qt.locale().toString(root.today, "yyyy")
                                font.pixelSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: DateTime.time
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Bold
                            font.features: { "tnum": 1 }
                            color: Appearance.colors.colPrimary
                        }
                    }

                    // 7-day week calendar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: 7
                            delegate: Rectangle {
                                required property int index

                                readonly property var date: {
                                    const today = root.today
                                    const dow = today.getDay()
                                    const d = new Date(today)
                                    d.setDate(today.getDate() - dow + index)
                                    return d
                                }
                                readonly property bool isToday: {
                                    const t = root.today
                                    return date.getDate()     === t.getDate() &&
                                           date.getMonth()    === t.getMonth() &&
                                           date.getFullYear() === t.getFullYear()
                                }

                                Layout.fillWidth: true
                                height: 56
                                radius: Appearance.rounding.normal
                                color: isToday
                                    ? Appearance.colors.colPrimaryContainer
                                    : Appearance.colors.colSurfaceContainerHigh

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: Qt.locale().toString(date, "ddd").slice(0, 2)
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: isToday
                                            ? Appearance.colors.colPrimary
                                            : Appearance.colors.colOnSurfaceVariant
                                        font.weight: isToday ? Font.Bold : Font.Normal
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: date.getDate()
                                        font.pixelSize: isToday
                                            ? Appearance.font.pixelSize.normal
                                            : Appearance.font.pixelSize.small
                                        font.weight: isToday ? Font.Bold : Font.Normal
                                        color: isToday
                                            ? Appearance.colors.colPrimary
                                            : Appearance.colors.colOnLayer1
                                    }
                                }
                            }
                        }
                    }

                    // Tasks section
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Column {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            MaterialShapeWrappedMaterialSymbol {
                                shape: MaterialShape.Shape.Clover4Leaf
                                text: "checklist"
                                iconSize: Appearance.font.pixelSize.large
                                implicitSize: 36
                                color: Appearance.colors.colPrimaryContainer
                                colSymbol: Appearance.colors.colPrimary
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: `${Todo.list.filter(t => !t.done).length}`
                                font.pixelSize: Appearance.font.pixelSize.huge
                                font.weight: Font.Bold
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                id: todoRepeater
                                model: {
                                    const uncompleted = []
                                    for (let i = 0; i < Todo.list.length; i++) {
                                        if (!Todo.list[i].done) {
                                            uncompleted.push({
                                                originalIndex: i,
                                                content: Todo.list[i].content,
                                                done: Todo.list[i].done
                                            })
                                        }
                                    }
                                    return uncompleted.slice(-3).reverse()
                                }

                                delegate: Rectangle {
                                    id: taskCard
                                    required property int index
                                    required property var modelData
                                    readonly property int total: todoRepeater.count
                                    readonly property bool isFirst: index === 0
                                    readonly property bool isLast: index === total - 1
                                    readonly property real bigRadius: Appearance.rounding.normal
                                    readonly property real smallRadius: Appearance.rounding.unsharpenmore

                                    Layout.fillWidth: true
                                    height: 32
                                    topLeftRadius:     isFirst ? bigRadius : smallRadius
                                    topRightRadius:    isFirst ? bigRadius : smallRadius
                                    bottomLeftRadius:  isLast  ? bigRadius : smallRadius
                                    bottomRightRadius: isLast  ? bigRadius : smallRadius
                                    color: taskMouseArea.containsMouse ? Appearance.colors.colSurfaceContainerHighest : Appearance.colors.colSurfaceContainerHigh

                                    Behavior on color {
                                        ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        MaterialSymbol {
                                            text: taskMouseArea.containsMouse ? "check_circle" : "radio_button_unchecked"
                                            iconSize: Appearance.font.pixelSize.small
                                            color: taskMouseArea.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: taskCard.modelData.content
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnLayer1
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: taskMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Todo.markDone(taskCard.modelData.originalIndex)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 56
                                visible: Todo.list.filter(t => !t.done).length === 0
                                radius: Appearance.rounding.normal
                                color: Appearance.colors.colSurfaceContainerHigh

                                StyledText {
                                    anchors.centerIn: parent
                                    text: Translation.tr("No pending tasks")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }

                    // System uptime
                    Rectangle {
                        Layout.fillWidth: true
                        height: 14
                        color: "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: "timelapse"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            StyledText {
                                text: Translation.tr("System Uptime")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            StyledText {
                                text: "•"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            StyledText {
                                text: DateTime.uptime
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "clockPopup"
        function toggle(): void {
            GlobalStates.clockPopupOpen = !GlobalStates.clockPopupOpen
        }
        function open(): void {
            GlobalStates.clockPopupOpen = true
        }
        function close(): void {
            GlobalStates.clockPopupOpen = false
        }
    }

    CompositorGlobalShortcut {
        name: "clockPopupToggle"
        description: "Toggles clock, calendar and tasks popup on press"
        onPressed: {
            GlobalStates.clockPopupOpen = !GlobalStates.clockPopupOpen
        }
    }
}
