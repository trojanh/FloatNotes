import SwiftUI
import AppKit

struct NoteCardView: View {
    @ObservedObject var noteModel: NoteObservable
    var onDelete: () -> Void
    var onTogglePin: () -> Void

    @State private var showOptions: Bool = false
    @State private var showAIMenu: Bool = false
    @State private var showCopiedBanner: Bool = false
    @ObservedObject private var aiService = AIService.shared

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
            // Top Header: Pin, Status Badge, View All Notes, Options, Close
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

                // Settings popover
                Button(action: { showOptions.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(noteModel.note.color.secondaryTextColor)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Card Styles & Options")
                .popover(isPresented: $showOptions, arrowEdge: .bottom) {
                    noteOptionsPopover
                }

                // Delete / Close button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(noteModel.note.color.secondaryTextColor.opacity(0.75))
                        .padding(2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Delete Sticky Note")
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

                if showCopiedBanner {
                    Text("Copied as Clean Text!")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.75))
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

            // Always Visible Bottom Footer: List controls, Copy, Font controls & AI Send
            HStack(spacing: 7) {
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

                // Font size decrement
                Button(action: {
                    if noteModel.note.fontSize > 11 { noteModel.note.fontSize -= 1 }
                }) {
                    Text("A-")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(noteModel.note.color.secondaryTextColor)
                        .padding(2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Smaller Text")

                // Font size increment
                Button(action: {
                    if noteModel.note.fontSize < 32 { noteModel.note.fontSize += 1 }
                }) {
                    Text("A+")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(noteModel.note.color.secondaryTextColor)
                        .padding(2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Larger Text")

                Spacer()

                // Configurable Send to AI button
                Button(action: {
                    showAIMenu.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 9))
                        Text("Send to AI")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(noteModel.note.color.textColor.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(noteModel.note.color.textColor.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(noteModel.note.color.textColor.opacity(0.18), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Send Note Content to ChatGPT or Claude")
                .popover(isPresented: $showAIMenu, arrowEdge: .top) {
                    aiDispatchPopover
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.03))
        }
        .frame(minWidth: 230, minHeight: 200)
        .background(
            ZStack {
                VisualEffectBackground(
                    material: .hudWindow,
                    blendingMode: .behindWindow
                )
                noteModel.note.color.swiftUIColor
                    .opacity(noteModel.note.opacity)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
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

    private func copyCleanText() {
        // Copies cleanly: converts unicode checkboxes to standard markdown [ ] / [x] for external apps
        let cleanText = noteModel.note.text
            .replacingOccurrences(of: "☐ ", with: "- [ ] ")
            .replacingOccurrences(of: "☑ ", with: "- [x] ")

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(cleanText, forType: .string)

        withAnimation {
            showCopiedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showCopiedBanner = false
            }
        }
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
                AIService.sendToChatGPT(text: clean)
                showAIMenu = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("Send to ChatGPT")
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
                    Text("Send to Claude")
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
}
