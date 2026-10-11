-- NVIDIA configuration (auto-detected: activates only if NVIDIA driver is loaded)
local has_nvidia = false
local nv_f = io.open("/proc/driver/nvidia/version", "r")
if nv_f then
    has_nvidia = true
    nv_f:close()
end

if has_nvidia then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
    hl.config({
        cursor = {
            no_hardware_cursors = true,
        }
    })
end

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Monitor configuration (Laptop & Desktop friendly)
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
hl.monitor({
    output   = "eDP-4",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@165",
    position = "auto",
    scale    = 1,
})
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Fix Fifine Headset hardware ALSA volume reset (if connected)
hl.exec_cmd("amixer -c Headset set Headphone 100% unmute 2>/dev/null || true")

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
