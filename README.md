# FlowGram

High-fidelity buffer management for terminal LLM users. A single-file Zsh script that adds powerful keyboard shortcuts for managing your command line buffer.

## Features

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Ctrl+A` | Select All | Visually highlights entire buffer |
| `Ctrl+K` | Nuke | Clears buffer (saves to undo cache) |
| `Ctrl+Z` | Undo | Restores last nuked content |

All actions display a subtle animation in the bottom-right corner that disappears after 500ms.

## Installation

### Quick Install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Davidtzuke/FlowGram/main/flowgram.zsh -o ~/.flowgram.zsh
source ~/.flowgram.zsh --install
```

### Manual Install

1. Clone the repo:
```bash
git clone https://github.com/Davidtzuke/FlowGram.git
```

2. Source and install:
```bash
cd FlowGram
source flowgram.zsh --install
```

3. Restart your terminal or run:
```bash
source ~/.zshrc
```

## Usage

Once installed, the keybindings are active in any Zsh session:

- Type something, press `Ctrl+K` to nuke it
- Press `Ctrl+Z` to bring it back
- Press `Ctrl+A` to select everything

The undo cache persists at `~/.flowgram_undo`, so you can recover even after closing the terminal.

## Requirements

- Zsh shell
- macOS or Linux with `tput` available

## License

MIT
