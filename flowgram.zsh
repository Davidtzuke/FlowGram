#!/usr/bin/env zsh
# flowgram.zsh - Minimal buffer management widgets
# Select All (Ctrl+A), Nuke (Ctrl+K), Undo (Ctrl+Z)

FLOWGRAM_UNDO="${HOME}/.flowgram_undo"

# Brief feedback in bottom-right corner
_flowgram_feedback() {
    local msg="$1"
    local cols=$(tput cols)
    local rows=$(tput lines)
    local col=$((cols - ${#msg} - 1))

    # Save cursor, move to bottom-right, print reversed, restore cursor
    tput sc
    tput cup $((rows - 1)) "$col"
    tput rev
    printf '%s' "$msg"
    tput sgr0
    tput rc

    # Clear after 0.5s in background
    {
        sleep 0.5
        tput sc
        tput cup $((rows - 1)) "$col"
        printf '%*s' "${#msg}" ""
        tput rc
    } &!
}

# Select All - select entire buffer
_flowgram_select_all() {
    [[ -z "$BUFFER" ]] && return
    MARK=0
    CURSOR=${#BUFFER}
    REGION_ACTIVE=1
    _flowgram_feedback "[selected]"
    zle -R
}

# Nuke - save buffer to undo file and clear
_flowgram_nuke() {
    [[ -z "$BUFFER" ]] && return
    printf '%s' "$BUFFER" > "$FLOWGRAM_UNDO"
    BUFFER=""
    CURSOR=0
    _flowgram_feedback "[nuked]"
    zle -R
}

# Undo - restore from undo file
_flowgram_undo() {
    [[ ! -r "$FLOWGRAM_UNDO" ]] && return
    local saved
    saved=$(<"$FLOWGRAM_UNDO")
    [[ -z "$saved" ]] && return
    BUFFER="$saved"
    CURSOR=${#BUFFER}
    : > "$FLOWGRAM_UNDO"
    _flowgram_feedback "[restored]"
    zle -R
}

# Register widgets
zle -N flowgram-select-all _flowgram_select_all
zle -N flowgram-nuke _flowgram_nuke
zle -N flowgram-undo _flowgram_undo

# Keybindings
# Ctrl variants
bindkey '^A' flowgram-select-all
bindkey '^K' flowgram-nuke
bindkey '^Z' flowgram-undo

# Alt/Meta variants (for terminals that send Cmd as Alt)
bindkey '\ea' flowgram-select-all
bindkey '\ek' flowgram-nuke
bindkey '\ez' flowgram-undo

# ============================================================================
# Auto-Install
# Usage: zsh flowgram.zsh install
#    or: curl -fsSL <url>/flowgram.zsh | zsh -s -- install
# ============================================================================
flowgram_install() {
    local src="${0:a}"
    local dest="${HOME}/.flowgram.zsh"
    local source_line='[[ -f ~/.flowgram.zsh ]] && source ~/.flowgram.zsh'
    local rc_file=""

    # Copy script to home
    if [[ -f "$src" ]]; then
        cp "$src" "$dest" || { echo "Error: Cannot copy to $dest"; return 1; }
    elif [[ -t 0 ]]; then
        echo "Error: No source file found"
        return 1
    else
        # Reading from stdin (curl pipe)
        cat > "$dest" || { echo "Error: Cannot write to $dest"; return 1; }
    fi
    chmod +x "$dest"

    # Find writable rc file
    for f in "${HOME}/.zshrc" "${HOME}/.zprofile"; do
        if [[ -w "$f" ]] || [[ ! -e "$f" ]]; then
            rc_file="$f"
            break
        fi
    done

    [[ -z "$rc_file" ]] && { echo "Error: No writable .zshrc or .zprofile"; return 1; }

    # Add source line if not present
    if ! grep -qF '.flowgram.zsh' "$rc_file" 2>/dev/null; then
        printf '\n# flowgram\n%s\n' "$source_line" >> "$rc_file"
        echo "Installed to $dest"
        echo "Added source line to $rc_file"
    else
        echo "Already installed in $rc_file"
    fi

    echo ""
    echo "Restart shell or run: source ~/.flowgram.zsh"
    echo ""
    echo "Keys:"
    echo "  Ctrl+A  Select all"
    echo "  Ctrl+K  Nuke (clear + save)"
    echo "  Ctrl+Z  Undo (restore)"
}

# Handle install argument
[[ "$1" == "install" ]] && { flowgram_install; return 0 2>/dev/null || exit 0; }
