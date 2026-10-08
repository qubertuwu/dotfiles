pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    Connections {
        target: Config.options.background
        function onLockWallChanged() {
            if (!Config.options.background.lockWall || Config.options.background.lockWall.length === 0) return
            genProc.command = [
                "bash", Directories.wallpaperSwitchScriptPath,
                "--colors_lock", "--image", FileUtils.trimFileProtocol(Config.options.background.lockWall)
            ]
            genProc.running = true
        }
    }

    Process {
        id: genProc
        onExited: (exitCode) => {
            if (exitCode === 0) {
                MaterialThemeLoader.useLockTheme();
            } else {
                console.warn("[LockWallpaperColorGen] switchwall.sh --colors_lock failed")
            }
        }
    }
}