import SwiftUI
import AppKit

struct NoteCardView: View {
    @ObservedObject var noteModel: NoteObservable
    var onDelete: () -> Void
    var onTogglePin: () -> Void

    @State private var showOptions: Bool = false
    @State private var showTextOptions: Bool = false
    @State private var showAIMenu: Bool = false
    @State private var showCopiedBanner: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showSmartActionSheet: Bool = false
    @State private var smartAlertMessage: String? = nil

    @ObservedObject private var aiService = AIService.shared
    @ObservedObject private var speechService = SpeechService.shared

    // Check if macOS 15+ Apple Intelligence / Writing Tools is available
    var isAppleIntelligenceAvailable: Bool {
        if #available(macOS 15.0, *) {
            return true
        }
        return false
    }

    var currentNSFont: NSFont {
        let size = CGFloat(noteModel.note.fontSize)
        switch noteModel.note.fontDesign {
        case .standard:
            return NSFont.systemFont(ofSize: size)
        case .rounded:
            if let desc = NSFont.systemFont(ofSize: size).fontDescriptor.withDesign(.rounded),
               let font = NSFont(descriptor: desc, size: size) {
                return font
            }
            return NSFont.systemFont(ofSize: size)
        case .monospaced:
            return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        case .serif:
            if let desc = NSFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif),
               let font = NSFont(descriptor: desc, size: size) {
                return font
            }
            return NSFont.systemFont(ofSize: size)
        }
    }

    var currentNSColor: NSColor {
        switch noteModel.note.color {
        case .graphite:
            return NSColor.white.withAlphaComponent(0.95)
        default:
            return NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.17, alpha: 1.0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Header: Pin, Status Badge, Smart Suggestion, View All Notes, Options, Hide
            HStack(spacing: 6) {
                // Pin Button
                Button(action: onTogglePin) {
                    Image(systemName: noteModel.note.isPinnedOnTop ? "pin.fill" : "pin.slash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(noteModel.note.isPinnedOnTop ? .accentColor : noteModel.note.color.secondaryTextColor)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(noteModel.note.isPinnedOnTop ? "Always on Top (Active)" : "Standard Window Level")

                // Status Badge (todo, doing, done)
                StatusBadgeView(status: $noteModel.note.status)

                Spacer()

                // Smart Categorization & Calendar/Reminder Quick Action
                Button(action: { showSmartActionSheet.toggle() }) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(noteModel.note.color.secondaryTextColor)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Smart Actions (Categorize, Reminders, Calendar)")
                .popover(isPresented: $showSmartActionSheet, arrowEdge: .bottom) {
                    smartActionsPopover
                }

                // View All Notes Button
                Button(action: {
                    WindowManager.shared.showAllNotesWindow()
                }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(noteModel.note.color.secondaryTextColor)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("View All Notes")

                // Appearance & Color popover
                Button(action: { showOptions.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(noteModel.note.color.secondaryTextColor)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Card Styles & Color")
                .popover(isPresented: $showOptions, arrowEdge: .bottom) {
                    noteOptionsPopover
                }

                // Close button: Hides the floating note (doesn't delete it)
                Button(action: {
                    WindowManager.shared.hideNote(id: noteModel.note.id)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(noteModel.note.color.secondaryTextColor.opacity(0.75))
                        .padding(2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Hide Sticky Note (Reopen from View All or Menu Bar)")
            }
            .padding(.horizontal, 10)
            .padding(.top, 9)
            .padding(.bottom, 4)

            // Plain text editor with smart clickable checkboxes
            ZStack(alignment: .top) {
                CustomTextEditor(
                    text: $noteModel.note.text,
                    font: currentNSFont,
                    textColor: currentNSColor
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 2)

                // Copied / Smart Alert Banner
                if showCopiedBanner {
                    Text(smartAlertMessage ?? "Copied as Clean Text!")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.80))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .transition(.opacity.combined(with: .scale))
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .opacity(0.15)
                .padding(.horizontal, 8)

            // Always Visible Bottom Footer: List controls, Voice Dictation, Copy, Font controls, AI Send & Delete
            HStack(spacing: 6) {
                // Interactive Checklist button
                Button(action: insertChecklist) {
                    Image(systemName: "checklist")
                        .font(.system(size: 11))
                        .foregroundColor(noteModel.note.color.secondaryTextColor)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Insert Clickable Checklist (☐)")

                // Bullet button
                Button(action: insertBullet) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11))
                        .foregroundColor(noteModel.note.color.secondaryTextColor)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Insert Bullet (•)")

                // Voice Dictation Scratchpad
                Button(action: toggleVoiceDictation) {
                    Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 11))
                        .foregroundColor(speechService.isRecording ? .red : noteModel.note.color.secondaryTextColor)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(speechService.isRecording ? "Stop Voice Dictation" : "Voice Dictation Scratchpad")

                // Copy Clean Text Button
                Button(action: copyCleanText) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(noteModel.note.color.secondaryTextColor)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Copy as Clean Markdown/Plain Text")

                // Text Formatting & Typography Settings Toggle Button
                Button(action: { showTextOptions.toggle() }) {
                    Image(systemName: "textformat")
                        .font(.system(size: 11))
                        .foregroundColor(noteModel.note.color.secondaryTextColor)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Text Settings (Font size, family & style)")
                .popover(isPresented: $showTextOptions, arrowEdge: .top) {
                    textOptionsPopover
                }

                Spacer()

                // Modern Send to AI Button (Icon + Label in frosted pill)
                Button(action: {
                    showAIMenu.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                        Text("AI")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(noteModel.note.color.textColor.opacity(0.90))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        ZStack {
                            Color.white.opacity(0.20)
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.60), Color.white.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .help("Send Note to Gemini, ChatGPT, Claude, or Perplexity")
                .popover(isPresented: $showAIMenu, arrowEdge: .top) {
                    aiDispatchPopover
                }

                // Dedicated Delete Note Button with Confirmation Popover
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(noteModel.note.color.secondaryTextColor.opacity(0.75))
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Delete Sticky Note")
                .popover(isPresented: $showDeleteConfirmation, arrowEdge: .top) {
                    deleteConfirmationPopover
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.01), Color.black.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(minWidth: 180, minHeight: 120)
        .background(
            ZStack {
                // Frosted Glass Material
                VisualEffectBackground(
                    material: .popover,
                    blendingMode: .behindWindow
                )

                // Translucent Pastel Glass Tint Wash
                noteModel.note.color.swiftUIColor
                    .opacity(max(0.25, noteModel.note.opacity * 0.85))

                // Apple Glass Specular Glare / Reflection
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.30),
                        Color.white.opacity(0.05),
                        Color.black.opacity(0.04)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            // Precision Apple Glass Specular Rim Border
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.75),
                            Color.white.opacity(0.25),
                            Color.black.opacity(0.10),
                            Color.white.opacity(0.40)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
    }

    private func insertChecklist() {
        if noteModel.note.text.isEmpty {
            noteModel.note.text = "☐ "
        } else if noteModel.note.text.hasSuffix("\n") {
            noteModel.note.text += "☐ "
        } else {
            noteModel.note.text += "\n☐ "
        }
    }

    private func insertBullet() {
        if noteModel.note.text.isEmpty {
            noteModel.note.text = "• "
        } else if noteModel.note.text.hasSuffix("\n") {
            noteModel.note.text += "• "
        } else {
            noteModel.note.text += "\n• "
        }
    }

    private func toggleVoiceDictation() {
        if speechService.isRecording {
            speechService.stopRecording()
            showBanner(message: "Dictation ended")
        } else {
            speechService.requestAuthorization { granted in
                if granted {
                    let initialText = self.noteModel.note.text
                    self.speechService.startRecording { spoken in
                        if initialText.isEmpty {
                            self.noteModel.note.text = spoken
                        } else {
                            self.noteModel.note.text = "\(initialText)\n\(spoken)"
                        }
                    }
                    self.showBanner(message: "Listening...")
                } else {
                    self.showBanner(message: "Mic Permission Denied")
                }
            }
        }
    }

    private func copyCleanText() {
        let cleanText = noteModel.note.text
            .replacingOccurrences(of: "☐ ", with: "- [ ] ")
            .replacingOccurrences(of: "☑ ", with: "- [x] ")

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(cleanText, forType: .string)
        showBanner(message: "Copied as Clean Text!")
    }

    private func showBanner(message: String) {
        smartAlertMessage = message
        withAnimation {
            showCopiedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedBanner = false
            }
        }
    }

    // MARK: - Smart Actions Popover (Categorization + Calendar / Reminders)
    private var smartActionsPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.accentColor)
                Text("Smart Actions")
                    .font(.system(size: 12, weight: .bold))
            }

            // Apple Intelligence Writing Tools Banner if available
            if isAppleIntelligenceAvailable {
                HStack(spacing: 6) {
                    Image(systemName: "apple.intelligence")
                        .foregroundColor(.purple)
                    Text("Apple Intelligence Writing Tools active: Select text & right-click for proofread/rewrite.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(6)
                .background(Color.purple.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Divider()

            // 1. Smart Categorization
            if let suggestion = SmartCategorizationService.analyze(text: noteModel.note.text) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Smart Suggestion")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Button(action: {
                        if let s = suggestion.status { noteModel.note.status = s }
                        if let c = suggestion.color { noteModel.note.color = c }
                        showSmartActionSheet = false
                        showBanner(message: "Applied: \(suggestion.tagDescription)")
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                            Text(suggestion.tagDescription)
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text("Apply")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 2. Calendar / Reminder Extraction
            let detected = CalendarReminderService.shared.detectDates(in: noteModel.note.text)
            VStack(alignment: .leading, spacing: 6) {
                Text(detected.isEmpty ? "Reminders & Calendar" : "Detected Dates (\(detected.count))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                if let first = detected.first, let date = first.date {
                    Button(action: {
                        CalendarReminderService.shared.addToCalendar(title: noteModel.note.text.components(separatedBy: .newlines).first ?? "Event", startDate: date) { success, _ in
                            showSmartActionSheet = false
                            showBanner(message: success ? "Added to Apple Calendar!" : "Calendar failed")
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(.red)
                            Text("Add to Calendar (\(first.text))")
                                .font(.system(size: 11))
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: {
                    let firstLine = noteModel.note.text.components(separatedBy: .newlines).first ?? "Task"
                    let dueDate = detected.first?.date
                    CalendarReminderService.shared.addToReminders(title: firstLine, dueDate: dueDate) { success, _ in
                        showSmartActionSheet = false
                        showBanner(message: success ? "Saved to Reminders!" : "Reminders failed")
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checklist.checked")
                            .foregroundColor(.blue)
                        Text("Save as Apple Reminder")
                            .font(.system(size: 11))
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 250)
    }

    private var deleteConfirmationPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Delete Sticky Note?")
                .font(.system(size: 12, weight: .bold))

            Text("This action cannot be undone.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Button("Cancel") {
                    showDeleteConfirmation = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                Button("Delete") {
                    showDeleteConfirmation = false
                    onDelete()
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

    private var aiDispatchPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Send Note to AI")
                .font(.system(size: 12, weight: .bold))

            // AI Destination Config (App vs Web)
            VStack(alignment: .leading, spacing: 4) {
                Text("Destination Target")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    ForEach(AIDestination.allCases) { dest in
                        Button(action: {
                            aiService.preferredDestination = dest
                        }) {
                            Text(dest == .automatic ? "Auto" : (dest == .desktopApp ? "App" : "Web"))
                                .font(.system(size: 10, weight: aiService.preferredDestination == dest ? .semibold : .regular))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(aiService.preferredDestination == dest ? Color.accentColor : Color.primary.opacity(0.06))
                                .foregroundColor(aiService.preferredDestination == dest ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Action Buttons
            let clean = noteModel.note.text
                .replacingOccurrences(of: "☐ ", with: "- [ ] ")
                .replacingOccurrences(of: "☑ ", with: "- [x] ")

            Button(action: {
                AIService.sendToGemini(text: clean)
                showAIMenu = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .foregroundColor(.blue)
                    Text("Google Gemini")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Button(action: {
                AIService.sendToChatGPT(text: clean)
                showAIMenu = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("ChatGPT")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Button(action: {
                AIService.sendToClaude(text: clean)
                showAIMenu = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.orange)
                    Text("Claude")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Button(action: {
                AIService.sendToPerplexity(text: clean)
                showAIMenu = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .foregroundColor(.teal)
                    Text("Perplexity")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 250)
    }

    private var noteOptionsPopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("Card Appearance")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button(action: { showOptions = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            // Beautiful Color Palette Swatches
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Color")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(noteModel.note.color.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }

                HStack(spacing: 10) {
                    ForEach(NoteColor.allCases) { c in
                        ZStack {
                            Circle()
                                .fill(c.swiftUIColor)
                                .frame(width: 26, height: 26)
                                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)

                            if noteModel.note.color == c {
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 2.5)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(c == .graphite ? .white : Color.black.opacity(0.75))
                            } else {
                                Circle()
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                                    .frame(width: 26, height: 26)
                            }
                        }
                        .frame(width: 34, height: 34)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                noteModel.note.color = c
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Divider()

            // Typography Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Typography")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    ForEach(NoteFontDesign.allCases) { design in
                        Button(action: {
                            noteModel.note.fontDesign = design
                        }) {
                            Text(design.rawValue)
                                .font(.system(size: 11, weight: noteModel.note.fontDesign == design ? .semibold : .regular))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(noteModel.note.fontDesign == design ? Color.accentColor : Color.primary.opacity(0.06))
                                .foregroundColor(noteModel.note.fontDesign == design ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Card Opacity Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Card Opacity")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(noteModel.note.opacity * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }

                Slider(value: $noteModel.note.opacity, in: 0.4...1.0)
            }

            Divider()

            // Quick jump to All Notes view
            Button(action: {
                showOptions = false
                WindowManager.shared.showAllNotesWindow()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 11))
                    Text("Open All Notes View")
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 260)
    }

    private var textOptionsPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "textformat")
                    .foregroundColor(.accentColor)
                Text("Text Settings")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Button(action: { showTextOptions = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            // Font Size Controls
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Font Size")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(noteModel.note.fontSize)) pt")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }

                HStack(spacing: 8) {
                    Button(action: {
                        if noteModel.note.fontSize > 11 { noteModel.note.fontSize -= 1 }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "textformat.size.smaller")
                            Text("Smaller")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .help("Smaller Text (⌘-)")

                    Button(action: {
                        if noteModel.note.fontSize < 36 { noteModel.note.fontSize += 1 }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "textformat.size.larger")
                            Text("Larger")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .help("Larger Text (⌘+)")
                }
            }

            Divider()

            // Typography Design
            VStack(alignment: .leading, spacing: 6) {
                Text("Font Family")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    ForEach(NoteFontDesign.allCases) { design in
                        Button(action: {
                            noteModel.note.fontDesign = design
                        }) {
                            Text(design.rawValue)
                                .font(.system(size: 10, weight: noteModel.note.fontDesign == design ? .semibold : .regular))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(noteModel.note.fontDesign == design ? Color.accentColor : Color.primary.opacity(0.06))
                                .foregroundColor(noteModel.note.fontDesign == design ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 220)
    }
}
