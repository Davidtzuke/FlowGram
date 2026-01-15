# FlowGram

Buffer management + floating wave animation for terminal LLM users.

## Install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/Davidtzuke/FlowGram/main/flowgram.zsh -o ~/.flowgram.zsh && FLOWGRAM_AUTO_INSTALL=1 source ~/.flowgram.zsh
```

That's it. Works instantly.

## Keybindings

| Keys | Action |
|------|--------|
| `Ctrl+A` / `Cmd+A` | Select all |
| `Ctrl+K` / `Cmd+K` | Nuke buffer (with undo) |
| `Ctrl+Z` / `Cmd+Z` | Restore nuked content |
| `Ctrl+Delete` | Toggle animation on/off |

## Features

- **Wave animation**: "flowgram" floats in your prompt with a wave effect
- **Nuke & Undo**: Clear your buffer instantly, restore it anytime
- **Select All**: Visual selection of entire buffer
- **Non-blocking**: Animation runs in background, won't freeze terminal

## Requirements

- Zsh
- macOS or Linux
- Unicode-capable terminal

## License

MIT
