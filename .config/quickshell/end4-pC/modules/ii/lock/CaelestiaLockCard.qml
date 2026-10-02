pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.panels.lock

Item {
    id: cardRoot

    required property LockContext context
    property bool ctrlHeld: false
    readonly property var activePlayer: MprisController.activePlayer

    function forceFocus() {
        passwordBox.forceActiveFocus();
    }

    // Dynamic responsive size
    implicitWidth: Math.min(1060, Math.max(860, parent ? parent.width * 0.74 : 960))
    implicitHeight: Math.min(620, Math.max(490, parent ? parent.height * 0.62 : 540))

    // Entrance animation
    scale: 0.96
    opacity: 0
    Component.onCompleted: {
        scale = 1.0;
        opacity = 1.0;
        forceFocus();
    }
    Behavior on scale {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutQuad
        }
    }

    // Avatar resolution
    readonly property string resolvedAvatar: {
        if (Config.options.profile.avatarPath && Config.options.profile.avatarPath.length > 0) {
            let p = Config.options.profile.avatarPath;
            return p.startsWith("/") ? ("file://" + p) : p;
        }
        return "file://" + Quickshell.env("HOME") + "/.face";
    }

    // Main Floating Glassmorphic Container
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 32
        color: ColorUtils.applyAlpha(Appearance.colors.colLayer1, 0.90)
        border.color: Appearance.colors.colLayer0Border
        border.width: 1

        layer.enabled: true
        layer.effect: DropShadow {
            color: "#80000000"
            radius: 36
            samples: 35
            horizontalOffset: 0
            verticalOffset: 12
        }

        // 3-Column Content Layout
        RowLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18

            // ==========================================
            // 1. LEFT COLUMN: Weather & System Fetch
            // ==========================================
            ColumnLayout {
                Layout.fillHeight: true
                Layout.preferredWidth: 280
                Layout.maximumWidth: 300
                spacing: 14

                // Weather Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 110
                    radius: 20
                    color: Appearance.colors.colLayer2
                    border.color: Appearance.colors.colLayer0Border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            implicitWidth: 50
                            implicitHeight: 50
                            radius: 16
                            color: Appearance.colors.colPrimaryContainer

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: Icons.getWeatherIcon(Weather.data?.wCode) ?? "wb_sunny"
                                iconSize: 28
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: Weather.data?.temp ? (Weather.data.temp + (Weather.data.temp.includes("°") ? "" : "°")) : "+20°"
                                font.pixelSize: 24
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer2
                            }

                            StyledText {
                                text: Weather.data?.city ? Weather.data.city : "Казахстан"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: Appearance.colors.colPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: Weather.data?.description ? Weather.data.description : "Ясно"
                                font.pixelSize: 11
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Caelestia System Info Card ("caelestiafetch")
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 20
                    color: Appearance.colors.colLayer2
                    border.color: Appearance.colors.colLayer0Border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        // Shell header badge
                        RowLayout {
                            spacing: 8
                            Layout.fillWidth: true

                            Rectangle {
                                width: 22
                                height: 22
                                radius: 6
                                color: Appearance.colors.colPrimary

                                StyledText {
                                    anchors.centerIn: parent
                                    text: ">"
                                    color: Appearance.colors.colOnPrimary
                                    font.bold: true
                                    font.pixelSize: 12
                                }
                            }

                            StyledText {
                                text: "caelestiafetch.sh"
                                font.family: Appearance.font.family.monospace
                                font.pixelSize: 12
                                font.bold: true
                                color: Appearance.colors.colPrimary
                            }
                        }

                        Item { height: 2; width: 1 }

                        // Distro
                        RowLayout {
                            spacing: 8
                            MaterialSymbol {
                                text: "terminal"
                                iconSize: 16
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: (SystemInfo.distroName && SystemInfo.distroName !== "Unknown") ? SystemInfo.distroName : "CachyOS Linux"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer2
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Hostname
                        RowLayout {
                            spacing: 8
                            MaterialSymbol {
                                text: "computer"
                                iconSize: 16
                                color: Appearance.colors.colSecondary
                            }
                            StyledText {
                                text: SystemInfo.hostname ? SystemInfo.hostname : "localhost"
                                font.pixelSize: 11
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Kernel
                        RowLayout {
                            spacing: 8
                            MaterialSymbol {
                                text: "memory"
                                iconSize: 16
                                color: Appearance.colors.colTertiary
                            }
                            StyledText {
                                text: SystemInfo.kernelVersion ? ("Linux " + SystemInfo.kernelVersion) : "Linux x86_64"
                                font.pixelSize: 11
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Uptime
                        RowLayout {
                            spacing: 8
                            MaterialSymbol {
                                text: "schedule"
                                iconSize: 16
                                color: Appearance.colors.colOutline
                            }
                            StyledText {
                                text: "Аптайм: " + DateTime.uptime
                                font.pixelSize: 11
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Media player preview (if active)
                        RowLayout {
                            Layout.fillWidth: true
                            visible: cardRoot.activePlayer !== null && (cardRoot.activePlayer.playbackState === MprisPlaybackState.Playing)
                            spacing: 8

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: Appearance.colors.colPrimaryContainer

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "music_note"
                                    iconSize: 18
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                StyledText {
                                    text: cardRoot.activePlayer?.trackTitle || "Неизвестный трек"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Appearance.colors.colOnLayer2
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: cardRoot.activePlayer?.trackArtist || "Медиаплеер"
                                    font.pixelSize: 10
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // 2. CENTER COLUMN: Clock, Avatar, Password
            // ==========================================
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.minimumWidth: 320
                spacing: 8
                Layout.alignment: Qt.AlignHCenter

                Item { Layout.fillHeight: true }

                // Digital Clock (Caelestia dual-color typography)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2

                    StyledText {
                        text: DateTime.hourStr
                        font.pixelSize: 66
                        font.weight: Font.Black
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: ":"
                        font.pixelSize: 58
                        font.weight: Font.Bold
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: DateTime.minuteStr
                        font.pixelSize: 66
                        font.weight: Font.Black
                        color: Appearance.colors.colSecondary
                    }
                }

                // Date
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: DateTime.collapsedCalendarFormat.toUpperCase()
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                    font.letterSpacing: 2.0
                }

                Item { height: 8; width: 1 }

                // Avatar
                Rectangle {
                    id: avatarContainer
                    Layout.alignment: Qt.AlignHCenter
                    width: 76
                    height: 76
                    radius: 38
                    color: Appearance.colors.colPrimaryContainer
                    border.width: 2
                    border.color: Appearance.colors.colPrimary
                    clip: true

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: cardRoot.resolvedAvatar
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "person"
                        iconSize: 44
                        color: Appearance.colors.colOnPrimaryContainer
                        visible: avatarImg.status !== Image.Ready
                    }
                }

                // Username badge
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Quickshell.env("USER") || "qubert"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                }

                Item { height: 6; width: 1 }

                // Caelestia Pill Password Input Box
                Rectangle {
                    id: passwordPill
                    Layout.alignment: Qt.AlignHCenter
                    width: 290
                    height: 48
                    radius: 24
                    color: Appearance.colors.colLayer2
                    border.width: passwordBox.activeFocus ? 2 : 1
                    border.color: passwordBox.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 8

                        // Lock icon badge
                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: Appearance.colors.colPrimaryContainer

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "lock"
                                iconSize: 18
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }

                        // Password text input
                        TextInput {
                            id: passwordBox
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            inputMethodHints: Qt.ImhSensitiveData
                            font.pixelSize: 14
                            color: Appearance.colors.colOnLayer2
                            clip: true

                            property string placeholder: "Введите пароль..."

                            StyledText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: passwordBox.placeholder
                                font.pixelSize: 13
                                color: Appearance.colors.colSubtext
                                visible: passwordBox.text.length === 0
                            }

                            onTextChanged: cardRoot.context.currentText = text
                            onAccepted: cardRoot.context.tryUnlock(cardRoot.ctrlHeld)

                            Connections {
                                target: cardRoot.context
                                function onCurrentTextChanged() {
                                    if (passwordBox.text !== cardRoot.context.currentText) {
                                        passwordBox.text = cardRoot.context.currentText;
                                    }
                                }
                            }
                        }

                        // Submit / Arrow Button
                        Rectangle {
                            id: submitBtn
                            width: 40
                            height: 40
                            radius: 20
                            color: passwordBox.text.length > 0 ? Appearance.colors.colPrimary : Appearance.colors.colLayer1

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "arrow_forward"
                                iconSize: 18
                                color: passwordBox.text.length > 0 ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: cardRoot.context.tryUnlock(cardRoot.ctrlHeld)
                            }
                        }
                    }

                    // Shake animation on wrong password
                    SequentialAnimation {
                        id: wrongPasswordShakeAnim
                        NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x - 12; duration: 50 }
                        NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x + 12; duration: 50 }
                        NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x - 8; duration: 50 }
                        NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x + 8; duration: 50 }
                        NumberAnimation { target: passwordPill; property: "x"; to: passwordPill.x; duration: 50 }
                    }

                    Connections {
                        target: GlobalStates
                        function onScreenUnlockFailedChanged() {
                            if (GlobalStates.screenUnlockFailed) wrongPasswordShakeAnim.restart();
                        }
                    }
                }

                // Keyboard Layout / Error message row
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 20
                        radius: 6
                        color: Appearance.colors.colPrimaryContainer

                        StyledText {
                            anchors.centerIn: parent
                            text: HyprlandXkb.currentLayoutCode || "EN"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    StyledText {
                        text: {
                            if (GlobalStates.screenUnlockFailed) return "Неверный пароль";
                            if (cardRoot.context.unlockInProgress) return "Проверка...";
                            return "Нажмите Enter для входа";
                        }
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: GlobalStates.screenUnlockFailed ? Appearance.colors.colError : Appearance.colors.colSubtext
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ==========================================
            // 3. RIGHT COLUMN: Resources & Power Actions
            // ==========================================
            ColumnLayout {
                Layout.fillHeight: true
                Layout.preferredWidth: 280
                Layout.maximumWidth: 300
                spacing: 14

                // Hardware Resources Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 20
                    color: Appearance.colors.colLayer2
                    border.color: Appearance.colors.colLayer0Border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        // Header
                        RowLayout {
                            spacing: 8
                            MaterialSymbol {
                                text: "speed"
                                iconSize: 18
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: "Системные ресурсы"
                                font.bold: true
                                font.pixelSize: 13
                                color: Appearance.colors.colOnLayer2
                            }
                        }

                        Item { height: 4; width: 1 }

                        // CPU Meter
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                MaterialSymbol {
                                    text: "memory"
                                    iconSize: 15
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    text: "ЦП"
                                    font.pixelSize: 11
                                    color: Appearance.colors.colSubtext
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: Math.round(ResourceUsage.cpuUsage * 100) + "%"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 6
                                radius: 3
                                color: Appearance.colors.colLayer1

                                Rectangle {
                                    height: parent.height
                                    radius: 3
                                    color: Appearance.colors.colPrimary
                                    width: Math.min(parent.width, Math.max(0, parent.width * ResourceUsage.cpuUsage))
                                }
                            }
                        }

                        // RAM Meter
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                MaterialSymbol {
                                    text: "developer_board"
                                    iconSize: 15
                                    color: Appearance.colors.colSecondary
                                }
                                StyledText {
                                    text: "ОЗУ"
                                    font.pixelSize: 11
                                    color: Appearance.colors.colSubtext
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Appearance.colors.colSecondary
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 6
                                radius: 3
                                color: Appearance.colors.colLayer1

                                Rectangle {
                                    height: parent.height
                                    radius: 3
                                    color: Appearance.colors.colSecondary
                                    width: Math.min(parent.width, Math.max(0, parent.width * ResourceUsage.memoryUsedPercentage))
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Music Player Status
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: cardRoot.activePlayer != null

                            MaterialSymbol {
                                text: cardRoot.activePlayer?.isPlaying ? "music_note" : "pause"
                                iconSize: 16
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: {
                                    if (!cardRoot.activePlayer) return "Плеер не активен";
                                    const title = cardRoot.activePlayer.trackTitle || "Без названия";
                                    const artist = cardRoot.activePlayer.trackArtist ? (" • " + cardRoot.activePlayer.trackArtist) : "";
                                    return title + artist;
                                }
                                font.pixelSize: 11
                                color: Appearance.colors.colSubtext
                            }

                            MaterialSymbol {
                                text: cardRoot.activePlayer?.isPlaying ? "pause_circle" : "play_circle"
                                iconSize: 18
                                color: Appearance.colors.colPrimary
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cardRoot.activePlayer?.togglePlaying()
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: cardRoot.activePlayer == null

                            MaterialSymbol {
                                text: "music_off"
                                iconSize: 16
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                text: "Музыка не играет"
                                font.pixelSize: 11
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }

                // Power Actions Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 20
                    color: Appearance.colors.colLayer2
                    border.color: Appearance.colors.colLayer0Border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        // Suspend
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: suspendMouse.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "bedtime"
                                iconSize: 20
                                color: Appearance.colors.colPrimary
                            }

                            MouseArea {
                                id: suspendMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                            }
                        }

                        // Reboot
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: rebootMouse.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "restart_alt"
                                iconSize: 20
                                color: Appearance.colors.colSecondary
                            }

                            MouseArea {
                                id: rebootMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                            }
                        }

                        // Power off
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: powerMouse.containsMouse ? Appearance.colors.colError : Appearance.colors.colLayer1

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "power_settings_new"
                                iconSize: 20
                                color: powerMouse.containsMouse ? Appearance.colors.colOnError : Appearance.colors.colError
                            }

                            MouseArea {
                                id: powerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                            }
                        }
                    }
                }
            }
        }
    }
}
