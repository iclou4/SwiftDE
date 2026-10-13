# SwiftDE

![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue.svg)
![SwiftOS](https://img.shields.io/badge/SwiftOS-FA7343?logo=swift&logoColor=FA7343&labelColor=white&color=FA7343)
![Apple](https://img.shields.io/badge/Apple-000000?logo=apple&labelColor=000000)

A macOS Sequoia-inspired desktop environment built on Wayfire (C++/Wayland compositor).

## Overview

SwiftDE is a modern desktop environment for Linux that brings the elegance and usability of macOS Sequoia to the FOSS ecosystem. Built on Wayfire, a flexible Wayland compositor with plugin-based architecture.

## Design Philosophy

**Inspired by Apple's Human Interface Guidelines** — The visual design, interaction patterns, and system behaviors are modeled after macOS Sequoia. We credit Apple's design team for the original concepts.

**Built on Wayfire** — Leveraging Wayfire's plugin-based Wayland compositor with wlroots. C++17, meson build system.

**Pure Wayland, No GNOME Dependencies** — SwiftDE runs as a standalone Wayland compositor. Not a GNOME extension, not a fork of mutter — a complete desktop environment.

## Architecture

```
┌─────────────────────────────────────┐
│           Wayfire Core              │  ← Wayland Compositor (wlroots)
├─────────────────────────────────────┤
│  Plugins: tile, scale, expo, cube,  │  ← Window Management
│  decoration, wobbly, animate, ...   │
├─────────────────────────────────────┤
│       SwiftDE Shell Components      │  ← Panel, Dock, Launcher (planned)
├─────────────────────────────────────┤
│       Wayfire Config (INI)          │  ← Configuration
└─────────────────────────────────────┘
```

## Components (Planned)

| Component | Description |
|-----------|-------------|
| `swiftde-panel` | Top bar + dock (macOS-style) |
| `swiftde-launcher` | App launcher (Spotlight-style) |
| `swiftde-workspaces` | Mission Control-style workspace management |
| `swiftde-bg` | Wallpaper daemon |
| `swiftde-notifications` | Notification center |
| `swiftde-osd` | On-screen display (volume, brightness) |
| `swiftde-greeter` | Login/lock screen |
| `swiftde-settings` | Settings application |
| `swiftde-idle` | Idle detection & power management |

## Building

### Prerequisites

- C++17 compiler (GCC 11+ or Clang 13+)
- meson 1.0+, ninja
- Dependencies: `wayland-protocols`, `wlroots`, `cairo`, `pango`, `gdk-pixbuf`, `libxml2`, `json-c`, `libevdev`, `libinput`, `pixman`, `glm`, `fmt`, `spdlog`, `toml++`, `nlohmann-json`

### Build

```bash
# Clone the repository
git clone https://github.com/vladislavtd1-cpu/SwiftDE
cd SwiftDE

# Build
meson setup build
ninja -C build
```

### Testing

```bash
# From TTY (Ctrl+Alt+F3)
# Build on F1, test on F3:
./build/src/wayfire
```

## macOS-Style Features (Planned)

- **Dock** — Bottom-centered, magnification on hover, running app indicators
- **Top Bar** — Menu bar with app menus, system status, clock, control center
- **Mission Control** — Gesture-driven workspace overview with Exposé
- **Launchpad** — Full-screen app grid with folders
- **Control Center** — Quick toggles (Wi-Fi, Bluetooth, AirDrop, Focus modes)
- **Notification Center** — Grouped by app, interactive widgets
- **Window Management** — Native split view, Stage Manager, quick tiling shortcuts

## Credits

- **Apple** — macOS Sequoia design language (Human Interface Guidelines)
- **Wayfire Contributors** — Wayland compositor (wlroots-based)
- **wlroots Contributors** — Wayland compositor library

## License

GPL-3.0-or-later

## Contributing

This is a personal project. Issues and PRs welcome for bug fixes.