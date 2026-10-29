# 📝 Quick-Note

A lightning-fast, feature-rich layer-shell scratchpad and markdown note editor built with **Quickshell**, **Qt Quick**, and **Wayland**. Designed for power users on Hyprland who want immediate access to their notes via global shortcuts without spawning heavy terminal windows or standard desktop apps.

---

## ✨ Features

- **🚀 Instant Layer-Shell Overlay**: Binds directly to Hyprland as an overlay layer-shell window for ultra-fast toggling (`Super + Alt + N`).
- **📑 Multi-Tab Notebook Support**: Easily switch between distinct note files (`scratch`, `code`, `ideas`, or dynamic custom tabs) saved locally as markdown.
- **👁️ Rich Markdown Preview Mode**: Toggle between raw edit mode and formatted markdown preview instantly.
- **🔍 Inline Search**: Quickly find text within your active scratchpad buffer (`Ctrl + F`).
- **⚙️ Kate / Mousepad Style Settings Panel**: 
  - Toggle line numbers on or off 📊
  - Adjust font sizes dynamically (+ / -) 🔠
  - Toggle text wrapping ↩️
  - Select all & clear text utility buttons 🧹
- **💾 Automatic Background Persistence**: Notes autosave seamlessly to disk (`~/.local/share/quick-note/`) with visual sync indicators.

---

## 🛠️ Requirements

- [Quickshell](https://github.com/outfoxxed/quickshell) (Wayland QML toolkit)
- Wayland compositor (Hyprland recommended)
- QtQuick & QtQuick.Controls

---

## 🚀 Usage & Keybindings

- **Toggle Quick-Note**: `Super + Alt + N`
- **Close Window**: `Esc` (or click Close)
- **Search Note**: `Ctrl + F`
- **Actions/Palette**: `Ctrl + Shift + P`
