import AppKit
import SwiftUI
import Combine

final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var noteStore: NoteStore!
    private var cancellables = Set<AnyCancellable>()

    init(noteStore: NoteStore) {
        super.init()
        self.noteStore = noteStore
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        setupMenu()
        updateStatusItem()

        noteStore.$notes
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)

        noteStore.$areAllNotesHidden
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else { return }

        // Clean monochrome icon
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        let icon = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Floating Notes")?.withSymbolConfiguration(config)
        button.image = icon
        button.imagePosition = .imageLeading

        let inProgressCount = noteStore.inProgressNotesCount
        if noteStore.areAllNotesHidden {
            button.title = " (Hidden)"
            button.attributedTitle = NSAttributedString(
                string: " (Hidden)",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
            )
        } else if inProgressCount > 0 {
            button.title = " \(inProgressCount)"
            button.attributedTitle = NSAttributedString(
                string: " \(inProgressCount)",
                attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: NSColor.systemBlue
                ]
            )
        } else {
            button.title = ""
        }
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    @objc private func newNoteAction() {
        if noteStore.areAllNotesHidden {
            noteStore.showAllNotes()
        }
        let created = noteStore.createNote()
        WindowManager.shared.focusNote(id: created.id)
    }

    @objc private func viewAllNotesAction() {
        WindowManager.shared.showAllNotesWindow()
    }

    @objc private func toggleVisibilityAction() {
        noteStore.toggleAllNotesVisibility()
    }

    @objc private func exportNotesAction() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "FloatingNotes_Backup.json"
        savePanel.title = "Export Floating Notes"

        NSApp.activate(ignoringOtherApps: true)
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? noteStore.exportNotes(to: url)
        }
    }

    @objc private func importNotesAction() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Import Floating Notes"

        NSApp.activate(ignoringOtherApps: true)
        if openPanel.runModal() == .OK, let url = openPanel.url {
            try? noteStore.importNotes(from: url, append: true)
        }
    }

    @objc private func focusNoteAction(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? UUID {
            if noteStore.areAllNotesHidden {
                noteStore.showAllNotes()
            }
            WindowManager.shared.focusNote(id: id)
        }
    }

    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}

extension StatusBarController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // New Note item
        let newNoteItem = NSMenuItem(title: "New Sticky Note", action: #selector(newNoteAction), keyEquivalent: "n")
        newNoteItem.target = self
        menu.addItem(newNoteItem)

        // View All Notes item
        let allNotesItem = NSMenuItem(title: "View All Notes...", action: #selector(viewAllNotesAction), keyEquivalent: "o")
        allNotesItem.keyEquivalentModifierMask = [.command, .shift]
        allNotesItem.target = self
        menu.addItem(allNotesItem)

        // Toggle visibility
        let toggleTitle = noteStore.areAllNotesHidden ? "Show All Notes" : "Hide All Notes"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleVisibilityAction), keyEquivalent: "h")
        toggleItem.keyEquivalentModifierMask = [.option, .command]
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Export / Import items
        let exportItem = NSMenuItem(title: "Export Notes as JSON...", action: #selector(exportNotesAction), keyEquivalent: "e")
        exportItem.keyEquivalentModifierMask = [.command, .shift]
        exportItem.target = self
        menu.addItem(exportItem)

        let importItem = NSMenuItem(title: "Import Notes from JSON...", action: #selector(importNotesAction), keyEquivalent: "i")
        importItem.keyEquivalentModifierMask = [.command, .shift]
        importItem.target = self
        menu.addItem(importItem)

        menu.addItem(NSMenuItem.separator())

        // Quick list of active notes
        if noteStore.notes.isEmpty {
            let emptyItem = NSMenuItem(title: "No Sticky Notes", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            let headerItem = NSMenuItem(title: "Open Notes (\(noteStore.notes.count)):", action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            menu.addItem(headerItem)

            for (idx, note) in noteStore.notes.enumerated() {
                let snippet = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
                let displayTitle = snippet.isEmpty ? "Untitled Note \(idx + 1)" : String(snippet.prefix(25))
                let statusMark = "[\(note.status.shortLabel)]"
                let pinMark = note.isPinnedOnTop ? "📌" : "  "
                let noteItem = NSMenuItem(title: "\(pinMark) \(statusMark) \(displayTitle)", action: #selector(focusNoteAction(_:)), keyEquivalent: "")
                noteItem.representedObject = note.id
                noteItem.target = self
                menu.addItem(noteItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Floating Notes", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
}
