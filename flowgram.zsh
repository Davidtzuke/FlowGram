#!/usr/bin/env zsh
# ============================================================================
# flowgram.zsh - High-fidelity buffer management for terminal LLM users
# ============================================================================
# A single-file ZLE widget collection providing:
#   - Select All with visual feedback
#   - Surgical Nuke (clear buffer with undo cache)
#   - Persistent Undo from cache
#   - Non-intrusive ANSI animations
# ============================================================================

FLOWGRAM_CACHE_FILE="${HOME}/.flowgram_undo"
FLOWGRAM_ANIMATION_DURATION=0.5

# ============================================================================
# ANSI Animation Engine
# ============================================================================
# Displays a minimalist status message in the bottom-right corner
# without disturbing scrollback history or current buffer display
# ============================================================================

_flowgram_animate() {
    local message="$1"
    local color="$2"

    # Color codes
    local reset="\033[0m"
    local dim="\033[2m"
    local color_code=""

    case "$color" in
        red)     color_code="\033[91m" ;;
        green)   color_code="\033[92m" ;;
        yellow)  color_code="\033[93m" ;;
        blue)    color_code="\033[94m" ;;
        magenta) color_code="\033[95m" ;;
        cyan)    color_code="\033[96m" ;;
        *)       color_code="\033[97m" ;;
    esac

    # Get terminal dimensions
    local term_width=$(tput cols)
    local term_height=$(tput lines)

    # Calculate message position (bottom-right, with padding)
    local msg_len=${#message}
    local padding=2
    local col=$((term_width - msg_len - padding))
    local row=$((term_height - 1))

    # Ensure col is not negative
    (( col < 1 )) && col=1

    # Save cursor position, display message, then restore
    {
        # Save cursor and attributes
        tput sc

        # Move to bottom-right position
        tput cup "$row" "$col"

        # Print styled message (dim + color for subtle effect)
        printf "${dim}${color_code}%s${reset}" "$message"

        # Restore cursor position
        tput rc
    } 2>/dev/null

    # Schedule cleanup in background (non-blocking)
    {
        sleep "$FLOWGRAM_ANIMATION_DURATION"

        # Clear the message area
        tput sc
        tput cup "$row" "$col"
        printf "%*s" "$((msg_len + 1))" ""
        tput rc
    } &>/dev/null &
    disown 2>/dev/null
}

# ============================================================================
# Widget: Select All
# ============================================================================
# Highlights and selects the entire current line buffer
# Emulates Cmd+A behavior for terminal environments
# ============================================================================

_flowgram_select_all() {
    # Check if buffer has content
    if [[ -z "$BUFFER" ]]; then
        _flowgram_animate "[ empty ]" "yellow"
        return 0
    fi

    # Set the selection region to cover entire buffer
    # MARK = start of selection, CURSOR = end of selection
    MARK=0
    CURSOR=${#BUFFER}

    # Activate region highlighting (visual selection mode)
    zle set-mark-command
    REGION_ACTIVE=1

    # Trigger visual feedback
    _flowgram_animate "[selected]" "cyan"

    # Redisplay to show selection
    zle -R
}

# ============================================================================
# Widget: Surgical Nuke
# ============================================================================
# Instantly clears the buffer after saving content to persistent cache
# Allows recovery via Persistent Undo widget
# ============================================================================

_flowgram_nuke() {
    # Check if buffer is already empty
    if [[ -z "$BUFFER" ]]; then
        _flowgram_animate "[ empty ]" "yellow"
        return 0
    fi

    # Save current buffer to cache file (atomic write)
    printf '%s' "$BUFFER" > "$FLOWGRAM_CACHE_FILE" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        _flowgram_animate "[! error]" "red"
        return 1
    fi

    # Calculate stats for feedback
    local char_count=${#BUFFER}
    local line_count=$(printf '%s' "$BUFFER" | grep -c '^' 2>/dev/null || echo 1)

    # Clear the buffer
    BUFFER=""
    CURSOR=0

    # Deactivate any active region
    REGION_ACTIVE=0

    # Trigger animation with stats
    if (( char_count > 99 )); then
        _flowgram_animate "[nuked ${line_count}L]" "red"
    else
        _flowgram_animate "[ nuked ]" "red"
    fi

    # Redisplay
    zle -R
}

# ============================================================================
# Widget: Persistent Undo
# ============================================================================
# Restores the last nuked prompt from the cache file
# ============================================================================

_flowgram_undo() {
    # Check if cache file exists and is readable
    if [[ ! -r "$FLOWGRAM_CACHE_FILE" ]]; then
        _flowgram_animate "[no undo]" "yellow"
        return 0
    fi

    # Read cached content
    local cached_content
    cached_content=$(<"$FLOWGRAM_CACHE_FILE" 2>/dev/null)

    if [[ -z "$cached_content" ]]; then
        _flowgram_animate "[no undo]" "yellow"
        return 0
    fi

    # Restore buffer content
    BUFFER="$cached_content"
    CURSOR=${#BUFFER}

    # Clear the cache after restore (single-use undo)
    : > "$FLOWGRAM_CACHE_FILE" 2>/dev/null

    # Trigger animation
    _flowgram_animate "[restore]" "green"

    # Redisplay
    zle -R
}

# ============================================================================
# ZLE Widget Registration
# ============================================================================

zle -N flowgram-select-all _flowgram_select_all
zle -N flowgram-nuke _flowgram_nuke
zle -N flowgram-undo _flowgram_undo

# ============================================================================
# Keybindings
# ============================================================================
# Ctrl and Cmd (Meta) keys do the same thing
#
# Select All:  Ctrl+A / Cmd+A
# Nuke buffer: Ctrl+K / Cmd+K
# Undo:        Ctrl+Z / Cmd+Z
# ============================================================================

# Ctrl bindings
bindkey '^a' flowgram-select-all
bindkey '^k' flowgram-nuke
bindkey '^z' flowgram-undo

# Cmd/Meta bindings (Escape sequences sent by terminal for Cmd+key)
bindkey '\ea' flowgram-select-all   # Cmd+A / Meta+A / Esc then A
bindkey '\ek' flowgram-nuke         # Cmd+K / Meta+K / Esc then K
bindkey '\ez' flowgram-undo         # Cmd+Z / Meta+Z / Esc then Z

# Alternative escape sequences (some terminals use these)
bindkey '^[a' flowgram-select-all
bindkey '^[k' flowgram-nuke
bindkey '^[z' flowgram-undo

# ============================================================================
# Self-Installation Handler
# ============================================================================
# Usage: source flowgram.zsh --install
# Appends source command to .zshrc for persistent loading
# ============================================================================

_flowgram_install() {
    local script_path="${0:A}"  # Get absolute path of this script
    local zshrc_path="${HOME}/.zshrc"
    local source_line="source \"${script_path}\""
    local marker="# flowgram.zsh"

    # Check if already installed
    if grep -q "flowgram.zsh" "$zshrc_path" 2>/dev/null; then
        echo "\033[93m[flowgram]\033[0m Already installed in .zshrc"
        echo "           Location: $zshrc_path"
        return 0
    fi

    # Check if .zshrc exists
    if [[ ! -f "$zshrc_path" ]]; then
        # Create .zshrc if it doesn't exist
        touch "$zshrc_path" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "\033[91m[flowgram]\033[0m Could not create .zshrc"
            echo ""
            echo "  Manual install - add this line to your shell config:"
            echo "    $source_line"
            return 1
        fi
    fi

    # Check if .zshrc is writable
    if [[ ! -w "$zshrc_path" ]]; then
        echo "\033[93m[flowgram]\033[0m .zshrc is not writable (owned by another user)"
        echo ""
        echo "  Fix with:  sudo chown \$(whoami) ~/.zshrc"
        echo "  Then run:  source ${script_path} --install"
        echo ""
        echo "  Or manually add this line to your shell config:"
        echo "    $source_line"
        return 1
    fi

    # Append to .zshrc
    {
        echo ""
        echo "$marker - buffer management for terminal LLM users"
        echo "$source_line"
    } >> "$zshrc_path"

    if [[ $? -eq 0 ]]; then
        echo "\033[92m[flowgram]\033[0m Successfully installed!"
        echo "           Added to: $zshrc_path"
        echo ""
        echo "  Keybindings (Ctrl and Cmd do the same thing):"
        echo "    Ctrl+A / Cmd+A  Select entire buffer"
        echo "    Ctrl+K / Cmd+K  Nuke buffer (with undo cache)"
        echo "    Ctrl+Z / Cmd+Z  Restore last nuked content"
        echo ""
        echo "  Restart your shell or run: source ~/.zshrc"
    else
        echo "\033[91m[flowgram]\033[0m Installation failed!"
        echo ""
        echo "  Manual install - add this line to your shell config:"
        echo "    $source_line"
        return 1
    fi
}

# Handle --install flag
if [[ "${1:-}" == "--install" ]]; then
    _flowgram_install
    return 0 2>/dev/null || exit 0
fi

# ============================================================================
# Initialization Complete
# ============================================================================
if [[ -o interactive ]] && [[ "${1:-}" != "--install" ]]; then
    :
fi
