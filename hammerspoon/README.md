# Hammerspoon Config

Window management and app switching for macOS.

## Demo

https://github.com/johnzhou1402/devmaxxing/raw/main/hammerspoon/demo.mp4

## Hotkeys

All use `Hyper` key (`Cmd + Alt + Ctrl`):

| Key | Action |
|-----|--------|
| `Hyper + -` | Left half of screen |
| `Hyper + =` | Right half of screen |
| `Hyper + M` | Maximize window |
| `Hyper + Left/Right` | Cycle Cursor windows |
| `Hyper + Up` | Cycle Chrome windows |
| `Hyper + Down` | Cycle Sourcetree windows |
| `Hyper + R` | Reload config |

## Features

- **Window cycling with memory**: When switching back to Cursor from Chrome/Sourcetree, it remembers which Cursor window you were last on
- **Smart window detection**: Only cycles through visible, standard windows

## Installation

```bash
# Symlink to your actual .hammerspoon directory
ln -sf ~/devmaxxing/hammerspoon/init.lua ~/.hammerspoon/init.lua
```

Then reload Hammerspoon or press `Hyper + R`.
