import AppKit
import SwiftUI
import Combine

final class WindowManager: NSObject, NSWindowDelegate {
    static let shared = WindowManager()

    private var noteStore: NoteStore!
    private var panels: [UUID: FloatingNotePanel] = [:]
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
        }

        // Add or update existing windows
        for note in notes {
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

    private func createAndShowPanel(for note: StickyNote) {
        let noteBinding = Binding<StickyNote>(
            get: { [weak self] in
                self?.noteStore.notes.first(where: { $0.id == note.id }) ?? note
            },
            set: { [weak self] updatedNote in
                self?.noteStore.updateNote(updatedNote)
            }
        )

        let cardView = NoteCardView(
            note: noteBinding,
            onDelete: { [weak self] in
                self?.noteStore.deleteNote(id: note.id)
            },
            onTogglePin: { [weak self] in
                guard let self = self else { return }
                if var n = self.noteStore.notes.first(where: { $0.id == note.id }) {
                    n.isPinnedOnTop.toggle()
                    self.noteStore.updateNote(n)
                }
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
        }
    }
}
