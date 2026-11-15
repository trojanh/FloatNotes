import AppKit
import SwiftUI
import Combine

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
        panels[id]?.updateLevel(isPinned: isPinned)
        if let obs = noteObservables[id], obs.note.isPinnedOnTop != isPinned {
            obs.note.isPinnedOnTop = isPinned
        }
    }

    func updateNoteStatus(for id: UUID, status: NoteStatus) {
        if let obs = noteObservables[id] {
            obs.note.status = status
        }
    }

    private func createAndShowPanel(for note: StickyNote) {
        let observable = NoteObservable(note: note)
        noteObservables[note.id] = observable

        // Observe text/state changes from inside the card, debounce them, and update storage cleanly without synchronous re-entry
        let sub = observable.$note
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] updatedNote in
                self?.noteStore.updateNote(updatedNote)
            }
        noteCancellables[note.id] = sub

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
        if let panel = panels[id] {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showAllNotesWindow() {
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

        let window = NSWindow(
            contentRect: NSRect(x: 250, y: 250, width: 720, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "All Sticky Notes"
        window.center()
        window.contentView = NSHostingView(rootView: allNotesView)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.allNotesWindow = window
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
