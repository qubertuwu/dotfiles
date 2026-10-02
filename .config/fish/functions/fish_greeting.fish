function fish_greeting
    if command -v fastfetch &> /dev/null
        set -l sixels ~/.config/fastfetch/sixels/*.six
        if test (count $sixels) -gt 0
            set -l random_six (random choice $sixels)
            fastfetch --raw $random_six
        else
            fastfetch
        end
    end
end
