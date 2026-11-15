import Foundation

final class NoteObservable: ObservableObject, Identifiable {
    let id: UUID
    @Published var note: StickyNote

    init(note: StickyNote) {
        self.id = note.id
        self.note = note
    }
}
