# FloatNotes 📝✨

A sleek, lightweight, native macOS menu bar application for floating sticky notes that stay visible across window switches, Mission Control virtual desktops (Spaces), and full-screen applications.

Designed with modern macOS translucency, clickable checklists, status tracking, multi-AI dispatch, and JSON backup/sync.

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)
![License MIT](https://img.shields.io/badge/license-MIT-green)

---

## 🌟 Key Features

- **Cross-Space & Always On Top**: Floating borderless cards (`.floating` level + `.canJoinAllSpaces`) that don't vanish when switching spaces or working in full-screen apps.
- **Per-Note Pinning**: Toggle individual notes between floating on top or standard desktop window level with a single click.
- **Dynamic Status Bar Item**:
  - Clean monochrome menu bar icon.
  - Live badge counter displaying the count of **in-progress notes** (`doing`).
  - Quick dropdown menu to create notes, toggle visibility, view all notes, export/import backups, and jump directly to any active note.
- **Clickable Checklists**:
  - Dedicated checklist button (`☐`).
  - Click directly on `☐` to toggle it to `☑` without manually editing markdown syntax.
  - Fully editable text even when checkboxes are empty.
  - Smart list continuation on `Return` (supports checklists, bullets, and numbered lists).
- **Multi-AI Dispatch**:
  - One-click prompt dispatch to **Google Gemini**, **ChatGPT**, **Claude**, and **Perplexity**.
  - Configurable dispatch target: **Auto** (desktop app if installed, else web browser), **Desktop App**, or **Web Browser**.
  - Dedicated **Copy as Clean Text** button to paste cleanly into any markdown editor.
- **Status Badges**:
  - Quick status pill (`todo`, `doing`, `done`) with high-contrast status colors.
- **Live Transparency / Opacity Slider**:
  - Adjust card transparency from 40% up to 100% solid, allowing you to read text and documentation directly underneath the note.
- **All Sticky Notes Hub (`⇧⌘O`)**:
  - Centralized dashboard to view, search, and manage all pinned and unpinned notes.
  - Create and edit notes directly in place on the same screen.
  - Filter notes by status (`todo`, `doing`, `done`).
- **Safety First**: Confirmation popovers on note deletion to prevent accidental loss of important thoughts.
- **Local Persistence & Backup**:
  - Auto-saved locally to `~/Library/Application Support/FloatingNotes/notes.json`.
  - One-click **Export** and **Import** JSON backup functionality.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `⌘ N` | Create a new sticky note |
| `⇧ ⌘ O` | Open the "All Sticky Notes" overview window |
| `⌥ ⌘ H` | Toggle visibility (Show / Hide All Notes) |
| `⌘ +` / `⌘ =` | Increase font size of active note |
| `⌘ -` | Decrease font size of active note |
| `⌘ A` | Select all text in active note |
| `⌘ C` / `⌘ V` / `⌘ X` | Copy, Paste, Cut |
| `⌘ Z` / `⇧ ⌘ Z` | Undo and Redo |
| `⇧ ⌘ E` | Export notes to JSON backup |
| `⇧ ⌘ I` | Import notes from JSON backup |
| `⌘ Q` | Quit FloatNotes |

---

## 🚀 Installation & Running

### Option 1: Download Pre-Built Release
1. Go to the [Releases](https://github.com/trojanh/FloatNotes/releases) page.
2. Download `FloatNotes.zip`.
3. Unzip and drag `FloatNotes.app` into your `/Applications` folder.
4. Launch `FloatNotes.app`.

### Option 2: Build from Source
Ensure you have Xcode Command Line Tools installed (`xcode-select --install`):

```bash
# Clone the repository
git clone https://github.com/trojanh/FloatNotes.git
cd FloatNotes

# Build and package the release app bundle
./scripts/build_app.sh

# Launch the app
open build/FloatNotes.app
```

---

## 🛠️ Tech Stack & Architecture

- **Language**: Swift 5.9+ / Swift 6.1
- **UI Framework**: SwiftUI + AppKit (`NSPanel`, `NSVisualEffectView`, `NSTextView`)
- **Persistence**: Atomic local JSON storage with debounced disk persistence
- **Build System**: Swift Package Manager (SPM) with automated macOS app bundle packaging script

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
