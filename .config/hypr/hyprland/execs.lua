local vars = require("variables")
local fn   = require("utils.functions")

local function autostart()
    -- Keyring and auth
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("pgrep -x polkit-gnome-authentication-agent-1 >/dev/null || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &")

    -- Clipboard history
    hl.exec_cmd("pkill -x wl-paste || true; wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Auto delete trash 30 days old
    hl.exec_cmd("trash-empty 30 &")

    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. vars.cursorTheme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. vars.cursorSize)

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("pgrep -x mpris-proxy >/dev/null || mpris-proxy &")

    -- Start shell
    hl.exec_cmd("env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy qs -c end4-pC -d")
end

hl.on("hyprland.start", autostart)

-- Resizer listeners
local function apply_resizer_rules(win)
    local float_center = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }
    local pip_actions = fn.move_actions(win) or {}

    -- Bitwarden
    fn.resizer(win, "Bitwarden", 20, 54, float_center, true, "class")                                       -- Native app
    fn.resizer(win, "^Extension: %(Bitwarden Password Manager%) %- Bitwarden", 20, 54, float_center, false) -- Firefox
    fn.resizer(win, "nngceckbapebfimnlniiiahkandclblb", 20, 54, float_center, true, "class")                -- Chromium

    -- Picture in picture
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip_actions, false)
end

hl.on("window.title", apply_resizer_rules)
hl.on("window.open", apply_resizer_rules)
