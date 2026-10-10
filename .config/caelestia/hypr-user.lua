-- NVIDIA configuration
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.config({
    cursor = {
        no_hardware_cursors = true,
    }
})

-- Monitor configuration
hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@165",
    position = "auto",
    scale    = 1,
})

-- Fix Fifine Headset hardware ALSA volume reset
hl.exec_cmd("amixer -c Headset set Headphone 100% unmute")

-- end4-pC Quickshell Keybinds are managed in ~/.config/hypr/hyprland/keybinds.lua



-- Antigravity Unlocker environment variables
local ag_conf = io.open(os.getenv("HOME") .. "/.config/environment.d/ag-unlocker.conf", "r")
if ag_conf then
    for line in ag_conf:lines() do
        local k, v = line:match("^([%w_]+)=([%S]+)")
        if k and v then hl.env(k, v) end
    end
    ag_conf:close()
end
