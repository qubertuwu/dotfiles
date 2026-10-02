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


