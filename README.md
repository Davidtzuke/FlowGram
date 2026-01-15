# FlowGram

High-fidelity buffer management and animated prompt for terminal LLM users.

## Scripts

| Script | Description |
|--------|-------------|
| `flowgram.zsh` | Buffer management keybindings |
| `flowgram-anim.zsh` | Floating wave animation for prompt |

---

## flowgram.zsh - Buffer Management

Ctrl and Cmd keys do the same thing:

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Ctrl+A` / `Cmd+A` | Select All | Visually highlights entire buffer |
| `Ctrl+K` / `Cmd+K` | Nuke | Clears buffer (saves to undo cache) |
| `Ctrl+Z` / `Cmd+Z` | Undo | Restores last nuked content |

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/Davidtzuke/FlowGram/main/flowgram.zsh -o ~/.flowgram.zsh
source ~/.flowgram.zsh --install
```

---

## flowgram-anim.zsh - Wave Animation

A floating ASCII wave animation that displays "flowgram" in your prompt. Each letter moves up and down independently using Unicode block elements.

```
▃f▅l▇o█w▇g▅r▃a▁m
```

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/Davidtzuke/FlowGram/main/flowgram-anim.zsh -o ~/.flowgram-anim.zsh
echo 'source ~/.flowgram-anim.zsh' >> ~/.zshrc
source ~/.zshrc
```

### Commands

| Command | Description |
|---------|-------------|
| `flowgram-anim-start` | Start the animation |
| `flowgram-anim-stop` | Stop the animation |
| `flowgram-anim-restart` | Restart the animation |
| `flowgram-anim-status` | Check if running |
| `flowgram-prompt-restore` | Restore original prompt |

### Custom Prompt

Edit your PROMPT after sourcing:

```bash
PROMPT='$(_flowgram_get_anim) %F{245}%~%f ❯ '
```

---

## Requirements

- Zsh shell
- macOS or Linux
- Terminal with Unicode support

## License

MIT
