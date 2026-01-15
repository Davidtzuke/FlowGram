#!/usr/bin/env zsh
# ============================================================================
# flowgram.zsh - Buffer management + floating animation for terminal LLM users
# ============================================================================
# One-click install: curl -fsSL bit.ly/flowgram | zsh
# ============================================================================

FLOWGRAM_CACHE_FILE="${HOME}/.flowgram_undo"
FLOWGRAM_ANIM_FILE="/tmp/.flowgram_anim_$$"
FLOWGRAM_ANIM_ENABLED=1
FLOWGRAM_UPDATE_INTERVAL=0.1

# Kill existing animation on re-source
[[ -n "$FLOWGRAM_ANIM_PID" ]] && kill "$FLOWGRAM_ANIM_PID" 2>/dev/null
rm -f /tmp/.flowgram_anim_* 2>/dev/null

# ============================================================================
# Notifications (bottom-right corner)
# ============================================================================
_flowgram_notify() {
    local msg="$1" color="$2"
    local cc="" reset="\033[0m" dim="\033[2m"
    case "$color" in
        red) cc="\033[91m";; green) cc="\033[92m";;
        yellow) cc="\033[93m";; cyan) cc="\033[96m";; *) cc="\033[97m";;
    esac
    local w=$(tput cols) h=$(tput lines) l=${#msg}
    local c=$((w - l - 2)) r=$((h - 1))
    (( c < 1 )) && c=1
    { tput sc; tput cup "$r" "$c"; printf "${dim}${cc}%s${reset}" "$msg"; tput rc; } 2>/dev/null
    { sleep 0.5; tput sc; tput cup "$r" "$c"; printf "%*s" "$((l+1))" ""; tput rc; } &>/dev/null &
    disown 2>/dev/null
}

# ============================================================================
# Wave Animation
# ============================================================================
typeset -a _FG_W=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" "▂" "▁" " ")
typeset -a _FG_C=("%F{39}" "%F{44}" "%F{49}" "%F{84}" "%F{119}" "%F{154}" "%F{184}" "%F{214}")
typeset -a _FG_P=(0 2 4 6 8 10 12 14)

_flowgram_wave_loop() {
    local f="$1" t=0
    while true; do
        local o=""
        for ((i=1;i<=8;i++)); do
            local idx=$(((t+_FG_P[i])%16+1))
            o+="%F{240}${_FG_W[idx]}%f${_FG_C[i]}flowgram"[$i]"%f"
        done
        print -n "$o" > "$f"
        ((t++))
        sleep 0.1
    done
}

_flowgram_get_anim() {
    [[ "$FLOWGRAM_ANIM_ENABLED" -eq 1 && -r "$FLOWGRAM_ANIM_FILE" ]] && cat "$FLOWGRAM_ANIM_FILE" 2>/dev/null || print -n ""
}

_flowgram_anim_start() {
    [[ -n "$FLOWGRAM_ANIM_PID" ]] && kill "$FLOWGRAM_ANIM_PID" 2>/dev/null
    FLOWGRAM_ANIM_FILE="/tmp/.flowgram_anim_$$"
    print -n "flowgram" > "$FLOWGRAM_ANIM_FILE"
    _flowgram_wave_loop "$FLOWGRAM_ANIM_FILE" &!
    FLOWGRAM_ANIM_PID=$!
}

_flowgram_anim_stop() {
    [[ -n "$FLOWGRAM_ANIM_PID" ]] && kill "$FLOWGRAM_ANIM_PID" 2>/dev/null
    unset FLOWGRAM_ANIM_PID
    rm -f "$FLOWGRAM_ANIM_FILE" 2>/dev/null
}

# ============================================================================
# Widgets
# ============================================================================
_flowgram_toggle() {
    if [[ "$FLOWGRAM_ANIM_ENABLED" -eq 1 ]]; then
        FLOWGRAM_ANIM_ENABLED=0; _flowgram_anim_stop; _flowgram_notify "[anim off]" "yellow"
    else
        FLOWGRAM_ANIM_ENABLED=1; _flowgram_anim_start; _flowgram_notify "[anim on]" "green"
    fi
    zle -R
}

_flowgram_select_all() {
    [[ -z "$BUFFER" ]] && { _flowgram_notify "[ empty ]" "yellow"; return; }
    MARK=0; CURSOR=${#BUFFER}; zle set-mark-command; REGION_ACTIVE=1
    _flowgram_notify "[selected]" "cyan"; zle -R
}

_flowgram_nuke() {
    [[ -z "$BUFFER" ]] && { _flowgram_notify "[ empty ]" "yellow"; return; }
    printf '%s' "$BUFFER" > "$FLOWGRAM_CACHE_FILE"
    BUFFER=""; CURSOR=0; REGION_ACTIVE=0
    _flowgram_notify "[ nuked ]" "red"; zle -R
}

_flowgram_undo() {
    [[ ! -r "$FLOWGRAM_CACHE_FILE" ]] && { _flowgram_notify "[no undo]" "yellow"; return; }
    local c=$(<"$FLOWGRAM_CACHE_FILE")
    [[ -z "$c" ]] && { _flowgram_notify "[no undo]" "yellow"; return; }
    BUFFER="$c"; CURSOR=${#BUFFER}; : > "$FLOWGRAM_CACHE_FILE"
    _flowgram_notify "[restore]" "green"; zle -R
}

zle -N flowgram-select-all _flowgram_select_all
zle -N flowgram-nuke _flowgram_nuke
zle -N flowgram-undo _flowgram_undo
zle -N flowgram-toggle _flowgram_toggle

# ============================================================================
# Keybindings
# ============================================================================
bindkey '^a' flowgram-select-all
bindkey '^k' flowgram-nuke
bindkey '^z' flowgram-undo
bindkey '\ea' flowgram-select-all
bindkey '\ek' flowgram-nuke
bindkey '\ez' flowgram-undo
bindkey '^[[3;6~' flowgram-toggle
bindkey '^[[3;5~' flowgram-toggle
bindkey '\e^?' flowgram-toggle

# ============================================================================
# Prompt
# ============================================================================
setopt PROMPT_SUBST
[[ -z "$FLOWGRAM_ORIG_PROMPT" ]] && FLOWGRAM_ORIG_PROMPT="$PROMPT"
PROMPT='$(_flowgram_get_anim) %F{245}%1~%f %F{white}>%f '

# Cleanup on exit
trap '_flowgram_anim_stop' EXIT HUP TERM INT

# ============================================================================
# Auto-Install (downloads to ~/.flowgram.zsh and adds to shell config)
# ============================================================================
_flowgram_auto_install() {
    local target="$HOME/.flowgram.zsh"
    local zshrc="$HOME/.zshrc"
    local src='[[ -f ~/.flowgram.zsh ]] && source ~/.flowgram.zsh'

    # Download if running from curl pipe
    if [[ ! -f "$target" ]] || [[ "${FLOWGRAM_FORCE_INSTALL:-}" == "1" ]]; then
        curl -fsSL "https://raw.githubusercontent.com/Davidtzuke/FlowGram/main/flowgram.zsh" -o "$target" 2>/dev/null
    fi

    # Try to add to .zshrc
    if [[ -f "$zshrc" ]]; then
        if grep -q "flowgram.zsh" "$zshrc" 2>/dev/null; then
            return 0  # Already installed
        fi
        if [[ -w "$zshrc" ]]; then
            echo "" >> "$zshrc"
            echo "# flowgram" >> "$zshrc"
            echo "$src" >> "$zshrc"
            return 0
        fi
    else
        # Create new .zshrc
        echo "$src" > "$zshrc" 2>/dev/null && return 0
    fi

    # If we can't write to .zshrc, try .zprofile
    local zprof="$HOME/.zprofile"
    if [[ ! -f "$zprof" ]] || [[ -w "$zprof" ]]; then
        if ! grep -q "flowgram.zsh" "$zprof" 2>/dev/null; then
            echo "" >> "$zprof"
            echo "# flowgram" >> "$zprof"
            echo "$src" >> "$zprof"
            return 0
        fi
    fi

    return 1
}

# ============================================================================
# Main
# ============================================================================
if [[ "${1:-}" == "--install" ]] || [[ -n "$FLOWGRAM_AUTO_INSTALL" ]]; then
    _flowgram_auto_install
    if [[ $? -eq 0 ]]; then
        echo "\033[92m[flowgram]\033[0m Installed! Restart terminal or run: source ~/.zshrc"
    else
        echo "\033[93m[flowgram]\033[0m Loaded for this session."
        echo "  To persist, add to your shell config:"
        echo '  [[ -f ~/.flowgram.zsh ]] && source ~/.flowgram.zsh'
    fi
    echo ""
    echo "  Keys: ^A select | ^K nuke | ^Z undo | Ctrl+Del toggle anim"
fi

# Start animation
[[ -o interactive ]] && _flowgram_anim_start
