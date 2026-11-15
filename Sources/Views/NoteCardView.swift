import SwiftUI
import AppKit

struct NoteCardView: View {
    @Binding var note: StickyNote
    var onDelete: () -> Void
    var onTogglePin: () -> Void

    @State private var isHovered: Bool = false
    @State private var showOptions: Bool = false

    var currentNSFont: NSFont {
        let size = CGFloat(note.fontSize)
        switch note.fontDesign {
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
        switch note.color {
        case .graphite:
            return NSColor.white.withAlphaComponent(0.95)
        default:
            return NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.17, alpha: 1.0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 6) {
                // Pin Button
                Button(action: onTogglePin) {
                    Image(systemName: note.isPinnedOnTop ? "pin.fill" : "pin.slash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(note.isPinnedOnTop ? .accentColor : note.color.secondaryTextColor)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(note.isPinnedOnTop ? "Always on Top (Active)" : "Standard Window Level")

                // Status Badge (TODO, DOING, DONE)
                StatusBadgeView(status: $note.status)

                Spacer()

                // Quick List Buttons on Hover
                if isHovered || showOptions {
                    HStack(spacing: 4) {
                        // Insert Checklist
                        Button(action: insertChecklist) {
                            Image(systemName: "checklist")
                                .font(.system(size: 11))
                                .foregroundColor(note.color.secondaryTextColor)
                        }
                        .buttonStyle(.plain)
                        .help("Insert Checklist Item")

                        // Insert Bullet
                        Button(action: insertBullet) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 11))
                                .foregroundColor(note.color.secondaryTextColor)
                        }
                        .buttonStyle(.plain)
                        .help("Insert Bullet Item")

                        // Font size quick controls
                        Button(action: {
                            if note.fontSize > 11 { note.fontSize -= 1 }
                        }) {
                            Text("A-")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(note.color.secondaryTextColor)
                        }
                        .buttonStyle(.plain)
                        .help("Decrease Font Size")

                        Button(action: {
                            if note.fontSize < 32 { note.fontSize += 1 }
                        }) {
                            Text("A+")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(note.color.secondaryTextColor)
                        }
                        .buttonStyle(.plain)
                        .help("Increase Font Size")

                        // Options & AI Popover
                        Button(action: { showOptions.toggle() }) {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 12))
                                .foregroundColor(note.color.secondaryTextColor)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showOptions, arrowEdge: .bottom) {
                            noteOptionsPopover
                        }
                    }
                }

                // Delete / Close button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(note.color.secondaryTextColor.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Delete Sticky Note")
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .background(Color.clear)

            // Plain text editor with smart bullet / checklist support
            CustomTextEditor(
                text: $note.text,
                font: currentNSFont,
                textColor: currentNSColor
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 200, minHeight: 180)
        .background(
            ZStack {
                VisualEffectBackground(
                    material: .hudWindow,
                    blendingMode: .behindWindow
                )
                note.color.swiftUIColor
                    .opacity(note.opacity)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private func insertChecklist() {
        if note.text.isEmpty {
            note.text = "- [ ] "
        } else if note.text.hasSuffix("\n") {
            note.text += "- [ ] "
        } else {
            note.text += "\n- [ ] "
        }
    }

    private func insertBullet() {
        if note.text.isEmpty {
            note.text = "• "
        } else if note.text.hasSuffix("\n") {
            note.text += "• "
        } else {
            note.text += "\n• "
        }
    }

    private var noteOptionsPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note Settings & Actions")
                .font(.headline)
                .padding(.bottom, 2)

            // Send to AI Apps section
            VStack(alignment: .leading, spacing: 6) {
                Text("Send to AI App")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Button(action: {
                        AIService.sendToChatGPT(text: note.text)
                        showOptions = false
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("ChatGPT")
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        AIService.sendToClaude(text: note.text)
                        showOptions = false
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                            Text("Claude")
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            // Color palette
            VStack(alignment: .leading, spacing: 6) {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(NoteColor.allCases) { c in
                        Circle()
                            .fill(c.swiftUIColor)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .stroke(note.color == c ? Color.accentColor : Color.black.opacity(0.2), lineWidth: note.color == c ? 2 : 1)
                            )
                            .onTapGesture {
                                note.color = c
                            }
                    }
                }
            }

            Divider()

            // Font Style
            VStack(alignment: .leading, spacing: 6) {
                Text("Typography")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Font", selection: $note.fontDesign) {
                    ForEach(NoteFontDesign.allCases) { design in
                        Text(design.rawValue).tag(design)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Opacity
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Card Opacity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(note.opacity * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Slider(value: $note.opacity, in: 0.4...1.0)
            }
        }
        .padding(14)
        .frame(width: 250)
    }
}
