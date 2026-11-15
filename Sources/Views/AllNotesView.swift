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
            // Modern Header bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                    Text("All Sticky Notes")
                        .font(.system(size: 15, weight: .bold))
                    Text("(\(store.notes.count))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Export & Import Buttons
                Button(action: exportAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 11))
                        Text("Export")
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Export all notes to a JSON file")

                Button(action: importAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 11))
                        Text("Import")
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Import notes from a JSON backup file")

                // Status Filter
                Picker("", selection: $filterStatus) {
                    Text("All Status").tag("ALL")
                    ForEach(NoteStatus.allCases) { status in
                        Text(status.shortLabel).tag(status.rawValue)
                    }
                }
                .labelsHidden()
                .frame(width: 105)

                // New Note CTA
                Button(action: {
                    let created = store.createNote()
                    onSelectNote(created.id)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("New Note")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                TextField("Search in notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Pinned Section
                    if !pinnedNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.accentColor)
                                Text("Always On Top (Pinned)")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("• \(pinnedNotes.count)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 14)], spacing: 14) {
                                ForEach(pinnedNotes) { note in
                                    noteGridCard(note: note)
                                }
                            }
                        }
                    }

                    // Unpinned Section
                    if !unpinnedNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "pin.slash")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("Standard Window Level")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("• \(unpinnedNotes.count)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 14)], spacing: 14) {
                                ForEach(unpinnedNotes) { note in
                                    noteGridCard(note: note)
                                }
                            }
                        }
                    }

                    if filteredNotes.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 34))
                                .foregroundColor(.secondary.opacity(0.7))
                            Text("No matching notes")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Try adjusting your search or status filter.")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 680, minHeight: 480)
        .background(Color(NSColor.underPageBackgroundColor))
    }

    private func noteGridCard(note: StickyNote) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            HStack {
                StatusBadgeView(status: Binding(
                    get: { note.status },
                    set: { newStatus in
                        var updated = note
                        updated.status = newStatus
                        WindowManager.shared.updateNoteStatus(for: note.id, status: newStatus)
                        store.updateNote(updated, immediateSave: true)
                    }
                ))

                Spacer()

                // Pin toggle
                Button(action: {
                    var updated = note
                    updated.isPinnedOnTop.toggle()
                    WindowManager.shared.updatePanelLevel(for: note.id, isPinned: updated.isPinnedOnTop)
                    store.updateNote(updated, immediateSave: true)
                }) {
                    Image(systemName: note.isPinnedOnTop ? "pin.fill" : "pin.slash")
                        .font(.system(size: 11))
                        .foregroundColor(note.isPinnedOnTop ? .accentColor : note.color.secondaryTextColor)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(note.isPinnedOnTop ? "Unpin from Always on Top" : "Pin to Always on Top")

                // Delete
                Button(action: {
                    store.deleteNote(id: note.id)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(note.color.secondaryTextColor.opacity(0.7))
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Delete Note")
            }
            .padding(.horizontal, 10)
            .padding(.top, 9)
            .padding(.bottom, 6)

            // Note Text Snippet
            Text(note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Empty Note..." : note.text)
                .font(.system(size: 12))
                .foregroundColor(note.color.textColor)
                .lineLimit(5)
                .lineSpacing(2)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider()
                .opacity(0.12)
                .padding(.horizontal, 8)

            // Card Footer
            HStack(spacing: 6) {
                // Send to AI Menu
                Menu {
                    Button(action: {
                        AIService.sendToChatGPT(text: note.text)
                    }) {
                        Label("ChatGPT", systemImage: "sparkles")
                    }

                    Button(action: {
                        AIService.sendToClaude(text: note.text)
                    }) {
                        Label("Claude", systemImage: "brain.head.profile")
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 8))
                        Text("Send to AI")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(note.color.textColor.opacity(0.08))
                    .foregroundColor(note.color.textColor.opacity(0.85))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(note.color.textColor.opacity(0.15), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .fixedSize()

                Spacer()

                // Open Floating Note
                Button(action: {
                    onSelectNote(note.id)
                }) {
                    HStack(spacing: 3) {
                        Text("Open")
                            .font(.system(size: 10, weight: .semibold))
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.04))
        }
        .frame(height: 155)
        .background(
            ZStack {
                note.color.swiftUIColor
                    .opacity(0.92)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.09), radius: 4, x: 0, y: 2)
    }

    private func exportAction() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "FloatingNotes_Backup.json"
        savePanel.title = "Export Floating Notes"

        NSApp.activate(ignoringOtherApps: true)
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? store.exportNotes(to: url)
        }
    }

    private func importAction() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Import Floating Notes"

        NSApp.activate(ignoringOtherApps: true)
        if openPanel.runModal() == .OK, let url = openPanel.url {
            try? store.importNotes(from: url, append: true)
        }
    }
}
