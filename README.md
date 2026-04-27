# Rymond044 Hyprland dotfiles

> *My configuration for a clean, functional, and aesthetically pleasing Hyprland setup.*

## Showcase
<img width="2880" height="1800" alt="image" src="https://github.com/user-attachments/assets/82b2ab31-9af5-4327-ace6-e9958ac6f036" />

https://github.com/user-attachments/assets/44e4d759-637e-4236-847c-cd813c1b8619
> i wish github could load videos larger than 10mb >:|

## Features

- **Dynamic color schemes** – Wallust picks colors from your wallpaper and applies them across all supported applications (Waybar, Rofi, Kitty, etc.). Change your wallpaper and everything updates instantly.
- **Intelligent package management** – Custom fzf-based scripts let you install or remove regular and AUR packages with a fuzzy finder, and even bulk‑remove multiple packages at once – all from your terminal.
- **Hyprland power‑user tools** – Enabled `hyprsplit` for advanced multi‑monitor management and `hyprexpo` for a beautiful workspace overview. Also `monitui` is great for managing monitors!
- **Custom Arch logo screensaver** – A unique screensaver that displays the Arch logo (or any custom logo) when the system is idle.
- **TUI suite** – A collection of terminal‑based utilities integrated into the workflow:
  - `btop` – system monitor with matching theme
  - `bluetui` – Bluetooth management
  - `impala` – network connection manager
  - `wiremix` - audio mixer
  - `calcure` – calendar and task management
- **Seamless application launcher** – Rofi provides not only an app launcher but also a power menu, battery manager, and a dedicated applet launcher.
---

## Components

| Directory        | Description                                     |
|------------------|-------------------------------------------------|
| `hypr/`          | Hyprland, Hypridle, Hyprlock configurations     |
| `waybar/`        | Navigation bar                                  |
| `rofi/`          | App, powermenu, applets launcher                |
| `swaync/`        | Notification daemon                             |
| `kitty/`         | Terminal                                        |
| `wallust/`       | Adaptive color palette picker                   |
| `btop/`          | System monitor                                  |
| `fastfetch/`     | Main system information                         |
| `fontconfig/`    | Font settings                                   |
| `binc/`          | Custom scripts                                  |

---
> _With great power comes great responsibility..._

⚠️ **No installer provided** – I’m too lazy to write or generate one. Copy files carefully, as some scripts have dependencies and a few paths are hardcoded. Adjust them to your system before using.
