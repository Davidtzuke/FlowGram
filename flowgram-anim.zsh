#!/usr/bin/env zsh
# ============================================================================
# flowgram-anim.zsh - Persistent floating ASCII animation for terminal prompts
# ============================================================================
# Creates a wave animation effect with the word "flowgram" in the prompt
# Each letter floats up and down independently using Unicode block elements
# ============================================================================

# ============================================================================
# Cleanup: Kill any existing animation process
# ============================================================================
if [[ -n "$FLOWGRAM_ANIM_PID" ]] && kill -0 "$FLOWGRAM_ANIM_PID" 2>/dev/null; then
    kill "$FLOWGRAM_ANIM_PID" 2>/dev/null
    unset FLOWGRAM_ANIM_PID
fi

# ============================================================================
# Configuration
# ============================================================================
FLOWGRAM_WORD="flowgram"
FLOWGRAM_ANIM_FILE="/tmp/.flowgram_anim_$$"
FLOWGRAM_UPDATE_INTERVAL=0.1

# Wave frames: ascending then descending (creates smooth oscillation)
typeset -a FLOWGRAM_WAVE_FRAMES
FLOWGRAM_WAVE_FRAMES=(
    "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"
    "▇" "▆" "▅" "▄" "▃" "▂" "▁" " "
)

# Color palette for letters (subtle gradient)
typeset -a FLOWGRAM_COLORS
FLOWGRAM_COLORS=(
    "%F{39}"   # f - blue
    "%F{44}"   # l - cyan
    "%F{49}"   # o - teal
    "%F{84}"   # w - green
    "%F{119}"  # g - lime
    "%F{154}"  # r - yellow-green
    "%F{184}"  # a - yellow
    "%F{214}"  # m - orange
)

# Phase offsets for each letter (creates wave propagation)
typeset -a FLOWGRAM_PHASE_OFFSETS
FLOWGRAM_PHASE_OFFSETS=(0 2 4 6 8 10 12 14)

# ============================================================================
# Animation Engine (runs in background)
# ============================================================================
_flowgram_animation_loop() {
    local word="$FLOWGRAM_WORD"
    local word_len=${#word}
    local num_frames=${#FLOWGRAM_WAVE_FRAMES[@]}
    local tick=0
    local anim_file="$1"

    # Dim color for wave blocks
    local wave_color="%F{240}"
    local reset="%f"

    while true; do
        local output=""

        # Build the animated string
        for ((i = 1; i <= word_len; i++)); do
            local letter="${word[$i]}"
            local phase_offset="${FLOWGRAM_PHASE_OFFSETS[$i]}"
            local letter_color="${FLOWGRAM_COLORS[$i]}"

            # Calculate current frame for this letter
            local frame_idx=$(( (tick + phase_offset) % num_frames + 1 ))
            local wave_char="${FLOWGRAM_WAVE_FRAMES[$frame_idx]}"

            # Build: wave block under the letter
            output+="${wave_color}${wave_char}${reset}${letter_color}${letter}${reset}"
        done

        # Write to temp file (atomic via redirect)
        print -n "$output" > "$anim_file"

        # Increment tick and sleep
        ((tick++))
        sleep "$FLOWGRAM_UPDATE_INTERVAL"
    done
}

# ============================================================================
# Read animation state (called by prompt)
# ============================================================================
_flowgram_get_anim() {
    if [[ -r "$FLOWGRAM_ANIM_FILE" ]]; then
        cat "$FLOWGRAM_ANIM_FILE" 2>/dev/null
    else
        print -n "flowgram"
    fi
}

# ============================================================================
# Start the background animation process
# ============================================================================
_flowgram_start() {
    # Clean up old temp files
    rm -f /tmp/.flowgram_anim_* 2>/dev/null

    # Initialize the animation file
    print -n "flowgram" > "$FLOWGRAM_ANIM_FILE"

    # Start background loop (detached, no job control messages)
    _flowgram_animation_loop "$FLOWGRAM_ANIM_FILE" &!
    FLOWGRAM_ANIM_PID=$!

    # Export for child shells
    export FLOWGRAM_ANIM_PID
    export FLOWGRAM_ANIM_FILE
}

# ============================================================================
# Stop the animation
# ============================================================================
_flowgram_stop() {
    if [[ -n "$FLOWGRAM_ANIM_PID" ]]; then
        kill "$FLOWGRAM_ANIM_PID" 2>/dev/null
        unset FLOWGRAM_ANIM_PID
    fi
    rm -f "$FLOWGRAM_ANIM_FILE" 2>/dev/null
}

# ============================================================================
# Cleanup on shell exit
# ============================================================================
_flowgram_cleanup() {
    _flowgram_stop
}

# Register cleanup hooks
trap '_flowgram_cleanup' EXIT HUP TERM INT

# Also clean up on SIGHUP (terminal close)
zshexit() {
    _flowgram_cleanup
}

# ============================================================================
# Prompt Integration
# ============================================================================
# Enable prompt substitution for dynamic updates
setopt PROMPT_SUBST

# Example prompt configurations:

# Option 1: Animation in the left prompt
# PROMPT='$(_flowgram_get_anim) %F{white}❯%f '

# Option 2: Animation with directory
# PROMPT='$(_flowgram_get_anim) %F{245}%1~%f %F{white}❯%f '

# Option 3: Two-line prompt with animation
# PROMPT='$(_flowgram_get_anim)
# %F{245}%~%f %F{white}❯%f '

# Default: Set a minimal prompt with the animation
FLOWGRAM_PROMPT_BACKUP="$PROMPT"
PROMPT='$(_flowgram_get_anim) %F{245}%1~%f %F{white}❯%f '

# ============================================================================
# User Commands
# ============================================================================
flowgram-anim-start() {
    _flowgram_start
    echo "[flowgram] Animation started (PID: $FLOWGRAM_ANIM_PID)"
}

flowgram-anim-stop() {
    _flowgram_stop
    echo "[flowgram] Animation stopped"
}

flowgram-anim-restart() {
    _flowgram_stop
    _flowgram_start
    echo "[flowgram] Animation restarted (PID: $FLOWGRAM_ANIM_PID)"
}

flowgram-anim-status() {
    if [[ -n "$FLOWGRAM_ANIM_PID" ]] && kill -0 "$FLOWGRAM_ANIM_PID" 2>/dev/null; then
        echo "[flowgram] Animation running (PID: $FLOWGRAM_ANIM_PID)"
    else
        echo "[flowgram] Animation not running"
    fi
}

# Restore original prompt
flowgram-prompt-restore() {
    PROMPT="$FLOWGRAM_PROMPT_BACKUP"
    echo "[flowgram] Original prompt restored"
}

# ============================================================================
# Auto-start on source
# ============================================================================
_flowgram_start

# ============================================================================
# Usage info
# ============================================================================
if [[ "${1:-}" == "--help" ]]; then
    cat << 'EOF'
flowgram-anim.zsh - Floating ASCII animation for your prompt

Commands:
  flowgram-anim-start    Start the animation
  flowgram-anim-stop     Stop the animation
  flowgram-anim-restart  Restart the animation
  flowgram-anim-status   Check if animation is running
  flowgram-prompt-restore  Restore your original prompt

The animation runs in a background process and updates every 0.1s.
Each letter of "flowgram" floats up and down in a wave pattern.

To customize your prompt, edit the PROMPT variable after sourcing:
  PROMPT='$(_flowgram_get_anim) your-custom-prompt '

EOF
fi
