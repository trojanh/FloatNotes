import AppKit
import SwiftUI
import Combine

final class AllNotesWindow: NSWindow {
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown && event.clickCount == 2 {
            let loc = event.locationInWindow
            // Double click in the top ribbon (height - 65) toggles window zoom / maximize
            if loc.y >= self.frame.height - 65 {
                self.zoom(nil)
                return
            }
        }
        super.sendEvent(event)
    }
}

final class WindowManager: NSObject, NSWindowDelegate {
    static let shared = WindowManager()

    private var noteStore: NoteStore!
    private var panels: [UUID: FloatingNotePanel] = [:]
    private var noteObservables: [UUID: NoteObservable] = [:]
    private var noteCancellables: [UUID: AnyCancellable] = [:]
    private var allNotesWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func configure(with store: NoteStore) {
        self.noteStore = store

        store.$notes
            .sink { [weak self] notes in
                self?.syncWindows(with: notes)
            }
            .store(in: &cancellables)

        store.$areAllNotesHidden
            .sink { [weak self] hidden in
                self?.handleVisibilityToggle(hidden: hidden)
            }
            .store(in: &cancellables)
    }

    private func syncWindows(with notes: [StickyNote]) {
        let noteIds = Set(notes.map { $0.id })
        
        // Remove closed windows
        for (id, panel) in panels where !noteIds.contains(id) {
            panel.close()
            panels.removeValue(forKey: id)
            noteObservables.removeValue(forKey: id)
            noteCancellables.removeValue(forKey: id)
        }

        // Add or update existing windows
        for note in notes {
            if let obs = noteObservables[note.id] {
                // Update observable model if changed externally (avoid loop if text is identical)
                if obs.note != note {
                    obs.note = note
                }
            }

            if let existing = panels[note.id] {
                existing.updateLevel(isPinned: note.isPinnedOnTop)
                if !noteStore.areAllNotesHidden && note.isVisible {
                    if !existing.isVisible {
                        existing.orderFront(nil)
                    }
                } else {
                    existing.orderOut(nil)
                }
            } else if !noteStore.areAllNotesHidden && note.isVisible {
                createAndShowPanel(for: note)
            }
        }
    }

    func updatePanelLevel(for id: UUID, isPinned: Bool) {
        if var note = noteStore.notes.first(where: { $0.id == id }) {
            note.isPinnedOnTop = isPinned
            if isPinned && !note.isVisible {
                note.isVisible = true
            }
            noteStore.updateNote(note, immediateSave: true)
        }

        if let obs = noteObservables[id], obs.note.isPinnedOnTop != isPinned {
            obs.note.isPinnedOnTop = isPinned
            if isPinned {
                obs.note.isVisible = true
            }
        }

        if let panel = panels[id] {
            panel.updateLevel(isPinned: isPinned)
            if isPinned {
                panel.orderFront(nil)
            }
        } else if isPinned, let note = noteStore.notes.first(where: { $0.id == id }) {
            createAndShowPanel(for: note)
        }
    }

    func updateNoteSize(width: Double, height: Double) {
        // Update all existing floating panels in realtime
        for (id, panel) in panels {
            var currentFrame = panel.frame
            // Keep top-left origin fixed when resizing
            let diffHeight = height - Double(currentFrame.size.height)
            currentFrame.origin.y -= CGFloat(diffHeight)
            currentFrame.size.width = CGFloat(width)
            currentFrame.size.height = CGFloat(height)
            panel.setFrame(currentFrame, display: true, animate: true)

            if let obs = noteObservables[id] {
                obs.note.width = width
                obs.note.height = height
            }
        }

        // Persist to all notes in note store
        for i in 0..<noteStore.notes.count {
            noteStore.notes[i].width = width
            noteStore.notes[i].height = height
        }
        noteStore.saveNow()
    }

    func unpinAllNotes() {
        for (id, panel) in panels {
            panel.updateLevel(isPinned: false)
            if let obs = noteObservables[id] {
                obs.note.isPinnedOnTop = false
            }
        }
        noteStore.unpinAllNotes()
    }

    func reorganizePinnedNotes() {
        // Collect pinned notes in their current View All display order
        let pinnedNotes = noteStore.notes.filter { $0.isPinnedOnTop }
        guard !pinnedNotes.isEmpty else { return }

        // Find primary screen or current active screen visible frame
        let screen = NSScreen.main ?? NSScreen.screens.first
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        // Dock to the top right of the visible screen with padding
        let rightPadding: CGFloat = 24.0
        let topPadding: CGFloat = 20.0
        let noteSpacing: CGFloat = 14.0

        var currentTopY = visibleFrame.origin.y + visibleFrame.size.height - topPadding

        for note in pinnedNotes {
            let noteW = CGFloat(note.width)
            let noteH = CGFloat(note.height)
            let targetX = visibleFrame.origin.x + visibleFrame.size.width - noteW - rightPadding
            let targetY = currentTopY - noteH

            let targetFrame = NSRect(x: targetX, y: targetY, width: noteW, height: noteH)

            // Ensure window exists and is visible
            if let panel = panels[note.id] {
                panel.setFrame(targetFrame, display: true, animate: true)
                panel.updateLevel(isPinned: true)
                panel.orderFront(nil)
            } else {
                var updated = note
                updated.isVisible = true
                updated.x = Double(targetX)
                updated.y = Double(targetY)
                createAndShowPanel(for: updated)
            }

            // Update observable and store coordinates
            if let obs = noteObservables[note.id] {
                obs.note.x = Double(targetX)
                obs.note.y = Double(targetY)
                obs.note.isVisible = true
            }

            if let idx = noteStore.notes.firstIndex(where: { $0.id == note.id }) {
                noteStore.notes[idx].x = Double(targetX)
                noteStore.notes[idx].y = Double(targetY)
                noteStore.notes[idx].isVisible = true
            }

            currentTopY = targetY - noteSpacing
        }

        noteStore.saveNow()
    }

    func hideNote(id: UUID) {
        if var note = noteStore.notes.first(where: { $0.id == id }) {
            note.isVisible = false
            noteStore.updateNote(note, immediateSave: true)
        }
        panels[id]?.orderOut(nil)
    }

    func updatePanelOpacity(for id: UUID, opacity: Double) {
        panels[id]?.updateOpacity(opacity)
    }

    func updateNoteStatus(for id: UUID, status: NoteStatus) {
        if let obs = noteObservables[id] {
            obs.note.status = status
        }
    }

    func adjustFontSizeForActiveNote(delta: Double) {
        // Find the currently key / focused note window
        for (id, panel) in panels where panel.isKeyWindow {
            if let obs = noteObservables[id] {
                let newSize = max(11, min(36, obs.note.fontSize + delta))
                obs.note.fontSize = newSize
                noteStore.updateNote(obs.note, immediateSave: true)
                return
            }
        }

        // If none is key, adjust the most recently updated note
        if let first = noteObservables.values.first {
            let newSize = max(11, min(36, first.note.fontSize + delta))
            first.note.fontSize = newSize
            noteStore.updateNote(first.note, immediateSave: true)
        }
    }

    private func createAndShowPanel(for note: StickyNote) {
        let observable = NoteObservable(note: note)
        noteObservables[note.id] = observable

        // Observe text/state changes from inside the card, debounce them, and update storage cleanly without synchronous re-entry
        let sub = observable.$note
            .dropFirst()
            .sink { [weak self] updatedNote in
                self?.updatePanelOpacity(for: note.id, opacity: updatedNote.opacity)
            }

        let debounceSub = observable.$note
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] updatedNote in
                self?.noteStore.updateNote(updatedNote)
            }
        noteCancellables[note.id] = AnyCancellable {
            sub.cancel()
            debounceSub.cancel()
        }

        let cardView = NoteCardView(
            noteModel: observable,
            onDelete: { [weak self] in
                self?.noteStore.deleteNote(id: note.id)
            },
            onTogglePin: { [weak self] in
                guard let self = self else { return }
                var n = observable.note
                n.isPinnedOnTop.toggle()
                observable.note.isPinnedOnTop = n.isPinnedOnTop
                self.updatePanelLevel(for: note.id, isPinned: n.isPinnedOnTop)
                self.noteStore.updateNote(n, immediateSave: true)
            }
        )

        let panel = FloatingNotePanel(note: note, rootView: AnyView(cardView))
        panel.delegate = self
        panels[note.id] = panel
        panel.orderFront(nil)
    }

    private func handleVisibilityToggle(hidden: Bool) {
        for (id, panel) in panels {
            if hidden {
                panel.orderOut(nil)
            } else {
                if let note = noteStore.notes.first(where: { $0.id == id }), note.isVisible {
                    panel.orderFront(nil)
                }
            }
        }
    }

    func focusNote(id: UUID) {
        if var note = noteStore.notes.first(where: { $0.id == id }) {
            if !note.isVisible {
                note.isVisible = true
                noteStore.updateNote(note, immediateSave: true)
            }
        }

        if let panel = panels[id] {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showAllNotesWindow() {
        // When All Notes window is shown, make app visible in Dock / App Switcher (⌘Tab)
        NSApp.setActivationPolicy(.regular)

        if let existing = allNotesWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let allNotesView = AllNotesView(
            store: noteStore,
            onSelectNote: { [weak self] id in
                self?.allNotesWindow?.orderOut(nil)
                self?.focusNote(id: id)
            },
            onClose: { [weak self] in
                self?.allNotesWindow?.orderOut(nil)
            }
        )

        let window = AllNotesWindow(
            contentRect: NSRect(x: 250, y: 250, width: 720, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.delegate = self
        window.title = "FloatNotes"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isOpaque = false
        window.backgroundColor = .clear
        window.center()
        window.contentView = NSHostingView(rootView: allNotesView)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.allNotesWindow = window
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window === allNotesWindow {
            // Revert to accessory mode when All Notes window is closed
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // Save frame on move/resize
    func windowDidMove(_ notification: Notification) {
        guard let panel = notification.object as? FloatingNotePanel else { return }
        updateNoteFrame(for: panel)
    }

    func windowDidResize(_ notification: Notification) {
        guard let panel = notification.object as? FloatingNotePanel else { return }
        updateNoteFrame(for: panel)
    }

    private func updateNoteFrame(for panel: FloatingNotePanel) {
        let frame = panel.frame
        if var note = noteStore.notes.first(where: { $0.id == panel.noteId }) {
            note.x = Double(frame.origin.x)
            note.y = Double(frame.origin.y)
            note.width = Double(frame.size.width)
            note.height = Double(frame.size.height)
            noteStore.updateNote(note)
            if let obs = noteObservables[panel.noteId] {
                obs.note.x = note.x
                obs.note.y = note.y
                obs.note.width = note.width
                obs.note.height = note.height
            }
        }
    }
}
