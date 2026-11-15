import SwiftUI
import AppKit

struct AllNotesView: View {
    @ObservedObject var store: NoteStore
    var onSelectNote: (UUID) -> Void
    var onClose: () -> Void

    @State private var filterStatus: String = "ALL"
    @State private var searchText: String = ""
    @State private var noteToDelete: UUID? = nil
    @State private var showSizeSettings: Bool = false

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
        ZStack {
            // Full-window Deep Frosted Glass Blur & Dynamic Aurora Gradient
            VisualEffectBackground(material: .underWindowBackground, blendingMode: .behindWindow)

            LinearGradient(
                colors: [
                    Color.purple.opacity(0.08),
                    Color.blue.opacity(0.05),
                    Color.clear,
                    Color.indigo.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // Frosted Glass Top Toolbar
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("FloatNotes")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        Text("\(store.notes.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    .fixedSize(horizontal: true, vertical: false)

                    Spacer(minLength: 8)

                    // Export & Import Frosted Glass Pills
                    HStack(spacing: 4) {
                        Button(action: exportAction) {
                            HStack(spacing: 3) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 9))
                                Text("Export")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        .fixedSize(horizontal: true, vertical: false)
                        .help("Export all notes to a JSON file")

                        Button(action: importAction) {
                            HStack(spacing: 3) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 9))
                                Text("Import")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        .fixedSize(horizontal: true, vertical: false)
                        .help("Import notes from a JSON backup file")
                    }
                    .fixedSize(horizontal: true, vertical: false)

                    // Status Filter Segmented Pill
                    HStack(spacing: 2) {
                        filterButton(title: "All", tag: "ALL")
                        ForEach(NoteStatus.allCases) { status in
                            filterButton(title: status.shortLabel, tag: status.rawValue)
                        }
                    }
                    .padding(2.5)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                    )
                    .fixedSize(horizontal: true, vertical: false)

                    // Unpin All Button
                    Button(action: {
                        withAnimation {
                            WindowManager.shared.unpinAllNotes()
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "pin.slash")
                                .font(.system(size: 9))
                            Text("Unpin All")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                    .fixedSize(horizontal: true, vertical: false)
                    .help("Unpin all currently pinned floating notes")

                    // Default Note Size Settings Popover
                    Button(action: { showSizeSettings.toggle() }) {
                        Image(systemName: "aspectratio")
                            .font(.system(size: 11))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3.5)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                    .fixedSize(horizontal: true, vertical: false)
                    .help("Default Note Size & Shape Settings")
                    .popover(isPresented: $showSizeSettings, arrowEdge: .bottom) {
                        defaultSizeSettingsPopover
                    }

                    // Modern Glowing New Note CTA (Creates unpinned note in View All)
                    Button(action: {
                        _ = store.createNote(initialText: "New Note", isVisible: false, isPinned: false)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("New Note")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .fixedSize(horizontal: true, vertical: false)
                    .help("Create a new note in View All (unpinned by default)")
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 10)

                // Frosted Glass Search Capsule
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    TextField("Search notes, checklists, code...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                )
                .padding(.horizontal, 22)
                .padding(.bottom, 14)

                // Content Grid Scroll Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        // Pinned Section
                        if !pinnedNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "pin.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.accentColor)
                                    Text("Always On Top")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                    Text("• \(pinnedNotes.count)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 12)], spacing: 12) {
                                    ForEach(pinnedNotes) { note in
                                        noteGridCard(note: note)
                                    }
                                }
                            }
                        }

                        // Unpinned Section
                        if !unpinnedNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "pin.slash")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Text("Standard Window Level")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                    Text("• \(unpinnedNotes.count)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 12)], spacing: 12) {
                                    ForEach(unpinnedNotes) { note in
                                        noteGridCard(note: note)
                                    }
                                }
                            }
                        }

                        if filteredNotes.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 38))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("No notes found")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Create a new note or adjust your search filter.")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 70)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    private func filterButton(title: String, tag: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                filterStatus = tag
            }
        }) {
            Text(title)
                .font(.system(size: 11, weight: filterStatus == tag ? .bold : .medium, design: .rounded))
                .foregroundColor(filterStatus == tag ? .white : .secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    filterStatus == tag ?
                    AnyView(
                        LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    ) : AnyView(Color.clear)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
    }

    private func noteGridCard(note: StickyNote) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Bar
            HStack(spacing: 5) {
                // Pin Button
                Button(action: {
                    let newPinned = !note.isPinnedOnTop
                    WindowManager.shared.updatePanelLevel(for: note.id, isPinned: newPinned)
                }) {
                    Image(systemName: note.isPinnedOnTop ? "pin.fill" : "pin.slash")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(note.isPinnedOnTop ? .accentColor : note.color.secondaryTextColor)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(note.isPinnedOnTop ? "Unpin from Always on Top" : "Pin to Always on Top")

                // Status Badge
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

                // Delete Button with Popover
                Button(action: {
                    noteToDelete = note.id
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(note.color.secondaryTextColor.opacity(0.6))
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Delete Note")
                .popover(isPresented: Binding(
                    get: { noteToDelete == note.id },
                    set: { if !$0 { noteToDelete = nil } }
                ), arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Delete Sticky Note?")
                            .font(.system(size: 12, weight: .bold))

                        Text("This note will be permanently removed.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Button("Cancel") {
                                noteToDelete = nil
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            Spacer()

                            Button("Delete") {
                                let id = note.id
                                noteToDelete = nil
                                store.deleteNote(id: id)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(12)
                    .frame(width: 200)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 4)

            // Editable Note Text with zero opacity container (compact preview)
            TextEditor(text: Binding(
                get: { note.text },
                set: { newText in
                    var updated = note
                    updated.text = newText
                    store.updateNote(updated)
                }
            ))
            .font(.system(size: 11))
            .foregroundColor(note.color.textColor)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .opacity(0.12)
                .padding(.horizontal, 6)

            // Compact Card Footer
            HStack(spacing: 6) {
                // Send to AI Glass Pill Menu
                Menu {
                    Button(action: {
                        AIService.sendToGemini(text: note.text)
                    }) {
                        Label("Google Gemini", systemImage: "sparkle")
                    }

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

                    Button(action: {
                        AIService.sendToPerplexity(text: note.text)
                    }) {
                        Label("Perplexity", systemImage: "magnifyingglass.circle.fill")
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 7))
                        Text("AI")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.18))
                    .foregroundColor(note.color.textColor.opacity(0.85))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .fixedSize()

                Spacer()

                // Open / Float Note Button with Glass Gradient
                Button(action: {
                    onSelectNote(note.id)
                }) {
                    HStack(spacing: 3) {
                        Text(note.isVisible ? "Float" : "Open")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 7, weight: .bold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .help(note.isVisible ? "Bring floating card to front" : "Open as floating note")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.04))
        }
        .frame(height: 120)
        .background(
            ZStack {
                // Frosted Glass Layer
                VisualEffectBackground(material: .popover, blendingMode: .behindWindow)

                // Translucent Pastel Tint
                note.color.swiftUIColor
                    .opacity(0.70)

                // Glass Specular Glare
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.25),
                        Color.white.opacity(0.04),
                        Color.black.opacity(0.04)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            // Specular Rim Border
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.70),
                            Color.white.opacity(0.20),
                            Color.black.opacity(0.08),
                            Color.white.opacity(0.35)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
    }

    private var defaultSizeSettingsPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "aspectratio")
                    .foregroundColor(.accentColor)
                Text("Default Note Size")
                    .font(.system(size: 12, weight: .bold))
            }

            Text("Choose the default size and shape when creating new floating sticky notes:")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            VStack(spacing: 6) {
                // Compact Rectangle
                sizeOptionRow(
                    title: "Compact Rectangle",
                    subtitle: "240 x 180 pt",
                    icon: "rectangle",
                    width: 240,
                    height: 180
                )

                // Standard Note
                sizeOptionRow(
                    title: "Standard Sticky",
                    subtitle: "260 x 280 pt",
                    icon: "square",
                    width: 260,
                    height: 280
                )

                // Wide Card
                sizeOptionRow(
                    title: "Wide Landscape",
                    subtitle: "320 x 220 pt",
                    icon: "rectangle.ratio.16.9",
                    width: 320,
                    height: 220
                )

                // Large Canvas
                sizeOptionRow(
                    title: "Large Note",
                    subtitle: "340 x 360 pt",
                    icon: "viewfinder",
                    width: 340,
                    height: 360
                )
            }
        }
        .padding(12)
        .frame(width: 230)
    }

    private func sizeOptionRow(title: String, subtitle: String, icon: String, width: Double, height: Double) -> some View {
        let isSelected = (store.defaultNoteWidth == width && store.defaultNoteHeight == height)
        return Button(action: {
            store.defaultNoteWidth = width
            store.defaultNoteHeight = height
            WindowManager.shared.updateNoteSize(width: width, height: height)
            showSizeSettings = false
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.primary.opacity(0.05))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
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
