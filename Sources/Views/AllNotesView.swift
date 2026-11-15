import SwiftUI
import AppKit

struct AllNotesView: View {
    @ObservedObject var store: NoteStore
    var onSelectNote: (UUID) -> Void
    var onClose: () -> Void

    @State private var filterStatus: String = "ALL"
    @State private var searchText: String = ""

    var filteredNotes: [StickyNote] {
        store.notes.filter { note in
            let matchesStatus = (filterStatus == "ALL") || (note.status.rawValue == filterStatus)
            let matchesSearch = searchText.isEmpty || note.text.localizedCaseInsensitiveContains(searchText)
            return matchesStatus && matchesSearch
        }
    }

    var pinnedNotes: [StickyNote] {
        filteredNotes.filter { $0.isPinnedOnTop }
    }

    var unpinnedNotes: [StickyNote] {
        filteredNotes.filter { !$0.isPinnedOnTop }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "square.grid.2x2")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("All Sticky Notes")
                    .font(.headline)

                Spacer()

                // Filter status
                Picker("Status", selection: $filterStatus) {
                    Text("All Status").tag("ALL")
                    ForEach(NoteStatus.allCases) { status in
                        Text(status.rawValue).tag(status.rawValue)
                    }
                }
                .frame(width: 130)

                Button(action: {
                    let created = store.createNote()
                    onSelectNote(created.id)
                }) {
                    Label("New Note", systemImage: "plus")
                }

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Content Grid
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Pinned Section
                    if !pinnedNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "pin.fill")
                                    .foregroundColor(.accentColor)
                                Text("Always On Top (Pinned) — \(pinnedNotes.count)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
                                ForEach(pinnedNotes) { note in
                                    noteGridCard(note: note)
                                }
                            }
                        }
                    }

                    // Unpinned Section
                    if !unpinnedNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "pin.slash")
                                    .foregroundColor(.secondary)
                                Text("Standard Window (Unpinned) — \(unpinnedNotes.count)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
                                ForEach(unpinnedNotes) { note in
                                    noteGridCard(note: note)
                                }
                            }
                        }
                    }

                    if filteredNotes.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("No notes found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 550, minHeight: 420)
    }

    private func noteGridCard(note: StickyNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusBadgeView(status: Binding(
                    get: { note.status },
                    set: { newStatus in
                        var updated = note
                        updated.status = newStatus
                        store.updateNote(updated, immediateSave: true)
                    }
                ))

                Spacer()

                // Pin toggle button
                Button(action: {
                    var updated = note
                    updated.isPinnedOnTop.toggle()
                    WindowManager.shared.updatePanelLevel(for: note.id, isPinned: updated.isPinnedOnTop)
                    store.updateNote(updated, immediateSave: true)
                }) {
                    Image(systemName: note.isPinnedOnTop ? "pin.fill" : "pin.slash")
                        .font(.system(size: 11))
                        .foregroundColor(note.isPinnedOnTop ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)

                // Delete button
                Button(action: {
                    store.deleteNote(id: note.id)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Preview Text
            Text(note.text.isEmpty ? "Empty Note" : note.text)
                .font(.system(size: 12))
                .foregroundColor(note.color.textColor)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // AI send & Jump to note
            HStack {
                // Quick AI buttons
                Button(action: {
                    AIService.sendToChatGPT(text: note.text)
                }) {
                    Text("ChatGPT")
                        .font(.system(size: 9))
                }
                .buttonStyle(.borderless)

                Button(action: {
                    AIService.sendToClaude(text: note.text)
                }) {
                    Text("Claude")
                        .font(.system(size: 9))
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(action: {
                    onSelectNote(note.id)
                }) {
                    HStack(spacing: 2) {
                        Text("Open")
                        Image(systemName: "arrow.up.forward.app")
                    }
                    .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(10)
        .frame(height: 140)
        .background(
            ZStack {
                note.color.swiftUIColor
                    .opacity(0.85)
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
}
