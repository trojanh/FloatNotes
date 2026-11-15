import Foundation
import Combine
import SwiftUI

final class NoteStore: ObservableObject {
    @Published var notes: [StickyNote] = []
    @Published var areAllNotesHidden: Bool = false

    private let fileURL: URL
    private var saveWorkItem: DispatchWorkItem?

    init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("FloatingNotes", isDirectory: true)

        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        self.fileURL = dir.appendingPathComponent("notes.json")
        load()

        if notes.isEmpty {
            createNote(initialText: "Welcome to Floating Notes!\n\n• Stays across Spaces & Apps\n• Translucent & customizable\n• Toggle with Menu Bar icon")
        }
    }

    var visibleNotesCount: Int {
        if areAllNotesHidden { return 0 }
        return notes.filter { $0.isVisible }.count
    }

    var inProgressNotesCount: Int {
        if areAllNotesHidden { return 0 }
        return notes.filter { $0.isVisible && $0.status == .inProgress }.count
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([StickyNote].self, from: data) {
            self.notes = decoded
        }
    }

    func saveNow() {
        saveWorkItem?.cancel()
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func scheduleSave() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard let data = try? JSONEncoder().encode(self.notes) else { return }
            try? data.write(to: self.fileURL, options: .atomic)
        }
        saveWorkItem = workItem
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    @discardableResult
    func createNote(initialText: String = "", offset: CGPoint? = nil) -> StickyNote {
        let baseCount = notes.count
        let defaultX = 200.0 + Double((baseCount % 6) * 30)
        let defaultY = 250.0 + Double((baseCount % 6) * 30)

        var newNote = StickyNote()
        newNote.text = initialText
        newNote.x = offset?.x != nil ? Double(offset!.x) : defaultX
        newNote.y = offset?.y != nil ? Double(offset!.y) : defaultY

        notes.append(newNote)
        saveNow()
        return newNote
    }

    func updateNote(_ note: StickyNote, immediateSave: Bool = false) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx] = note
            if immediateSave {
                saveNow()
            } else {
                scheduleSave()
            }
        }
    }

    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        saveNow()
    }

    func toggleAllNotesVisibility() {
        areAllNotesHidden.toggle()
    }

    func showAllNotes() {
        areAllNotesHidden = false
        for i in 0..<notes.count {
            notes[i].isVisible = true
        }
        saveNow()
    }

    // MARK: - Export & Import

    func exportNotes(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(notes)
        try data.write(to: url, options: .atomic)
    }

    func importNotes(from url: URL, append: Bool = true) throws {
        let data = try Data(contentsOf: url)
        let imported = try JSONDecoder().decode([StickyNote].self, from: data)
        if append {
            // Give newly imported notes fresh IDs to avoid collisions
            let remapped = imported.map { item -> StickyNote in
                var n = item
                n.id = UUID()
                return n
            }
            self.notes.append(contentsOf: remapped)
        } else {
            self.notes = imported
        }
        saveNow()
    }
}
