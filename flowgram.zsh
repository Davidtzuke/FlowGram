#!/usr/bin/env zsh
# flowgram.zsh - Buffer management for terminal users
# Ctrl+A select | Ctrl+K nuke | Ctrl+Z undo

FLOWGRAM_UNDO="${HOME}/.flowgram_undo"

# Feedback in bottom-right corner
_fg_msg() {
    local m="$1" c=$(tput cols) r=$(tput lines)
    tput sc; tput cup $((r-1)) $((c-${#m}-1)); tput rev; printf '%s' "$m"; tput sgr0; tput rc
    { sleep 0.5; tput sc; tput cup $((r-1)) $((c-${#m}-1)); printf '%*s' "${#m}" ""; tput rc; } &!
}

# Widgets
_fg_select() {
    [[ -z "$BUFFER" ]] && { _fg_msg "[empty]"; return; }
    MARK=0; CURSOR=${#BUFFER}; REGION_ACTIVE=1
    _fg_msg "[selected]"; zle -R
}

_fg_nuke() {
    [[ -z "$BUFFER" ]] && { _fg_msg "[empty]"; return; }
    printf '%s' "$BUFFER" > "$FLOWGRAM_UNDO"
    BUFFER=""; CURSOR=0
    _fg_msg "[nuked]"; zle -R
}

_fg_undo() {
    [[ ! -r "$FLOWGRAM_UNDO" ]] && { _fg_msg "[no undo]"; return; }
    local s=$(<"$FLOWGRAM_UNDO")
    [[ -z "$s" ]] && { _fg_msg "[no undo]"; return; }
    BUFFER="$s"; CURSOR=${#BUFFER}; : > "$FLOWGRAM_UNDO"
    _fg_msg "[restored]"; zle -R
}

# Register
zle -N fg-select _fg_select
zle -N fg-nuke _fg_nuke
zle -N fg-undo _fg_undo

# Keybindings
bindkey '^a' fg-select
bindkey '^k' fg-nuke
bindkey '^z' fg-undo
bindkey '\ea' fg-select
bindkey '\ek' fg-nuke
bindkey '\ez' fg-undo

# Install function
_fg_install() {
    local dest="$HOME/.flowgram.zsh"
    local line='[[ -f ~/.flowgram.zsh ]] && source ~/.flowgram.zsh'

    # Download fresh copy
    curl -fsSL "https://raw.githubusercontent.com/Davidtzuke/FlowGram/main/flowgram.zsh" -o "$dest" 2>/dev/null
    [[ $? -ne 0 ]] && { echo "Download failed"; return 1; }

    # Try .zprofile first (user usually owns it), then .zshrc
    local rc=""
    for f in "$HOME/.zprofile" "$HOME/.zshrc"; do
        if [[ -w "$f" ]] || [[ ! -e "$f" ]]; then
            rc="$f"; break
        fi
    done

    if [[ -z "$rc" ]]; then
        echo "Loaded for this session only."
        echo "Add manually: $line"
        return 1
    fi

    grep -q "flowgram" "$rc" 2>/dev/null || echo -e "\n# flowgram\n$line" >> "$rc"

    echo "Installed! Run: source $rc"
    echo "Keys: ^A select | ^K nuke | ^Z undo"
}

# Handle args
case "${1:-}" in
    install|--install|-i) _fg_install; return 0 2>/dev/null || exit 0 ;;
esac
