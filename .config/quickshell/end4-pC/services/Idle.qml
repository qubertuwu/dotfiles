pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Idle management service with 10-minute display turn-off.
 */
Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: false

    Connections {
        target: Persistent
        function onReadyChanged() {
            root.inhibit = Persistent.states.idle.inhibit;
        }
    }

    function toggleInhibit(active = null) {
        if (active !== null) {
            root.inhibit = active;
        } else {
            root.inhibit = !root.inhibit;
        }
        Persistent.states.idle.inhibit = root.inhibit;
    }

    IdleMonitor {
        id: screenIdleMonitor
        timeout: 600 // 10 minutes
        enabled: !root.inhibit
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) {
                Quickshell.execDetached(["qs", "-c", "end4-pC", "ipc", "call", "lock", "activate"]);
                Hyprland.dispatch("hl.dsp.dpms({ action = 'disable' })");
            } else {
                Hyprland.dispatch("hl.dsp.dpms({ action = 'enable' })");
                Quickshell.execDetached(["qs", "-c", "end4-pC", "ipc", "call", "lock", "focus"]);
            }
        }
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            anchors {
                right: true
                bottom: true
            }
            mask: Region {
                item: null
            }
        }
    }
}