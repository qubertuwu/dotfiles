#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"
export BROWSER="firefox"

# Antigravity Unlocker environment
if [ -f "$HOME/.config/environment.d/ag-unlocker.conf" ]; then
    set -a
    source "$HOME/.config/environment.d/ag-unlocker.conf"
    set +a
fi
