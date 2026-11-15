# FloatingNotes 📝

A sleek, lightweight macOS menu bar app for floating sticky notes that stay visible across window switches, virtual desktops (Mission Control Spaces), and full-screen applications.

## ✨ Features

- **Cross-Space & Always on Top**: Floating borderless cards (`.floating` level + `.canJoinAllSpaces`) that don't vanish when switching spaces or switching between full-screen apps.
- **Translucent Minimalist Design**: macOS vibrancy HUD material background with customizable card tint colors (Warm Yellow, Frosted White, Graphite, Lavender, Mint, Sky Blue) and adjustable card opacity.
- **Plain-Text Editor with Customization**:
  - Quick font size increment (`A+`) and decrement (`A-`) controls on hover.
  - Typography options: Default System, Rounded, Monospaced, and Serif.
- **Status Bar Integration**:
  - Clean monochrome `note.text` SF Symbol in your macOS menu bar.
  - Dynamic badge showing the count of currently visible floating notes.
  - Dropdown menu with:
    - **New Sticky Note** (`⌘N`)
    - **Hide All / Show All Notes** (`⌥⌘H` global toggle)
    - Active notes list to immediately jump to and focus any card
    - Quit option
- **Persistence**: Automatically persists note text, positions, dimensions, and styling to Application Support (`~/Library/Application Support/FloatingNotes/notes.json`).

---

## 🚀 Building & Running

### Option 1: Quick App Build & Run
Run the packaging script to generate `build/FloatingNotes.app`:

```bash
./scripts/build_app.sh
open build/FloatingNotes.app
```

### Option 2: Swift Command Line Run (Debug)
```bash
swift run
```
