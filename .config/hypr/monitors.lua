-- Laptop internal display (eDP-1, eDP-4)
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

-- Desktop primary display
hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@165",
    position = "0x0",
    scale    = 1,
})

-- Fallback for any other display
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
