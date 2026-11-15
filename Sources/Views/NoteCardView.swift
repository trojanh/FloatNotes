import SwiftUI
import AppKit

struct NoteCardView: View {
    @Binding var note: StickyNote
    var onDelete: () -> Void
    var onTogglePin: () -> Void

    @State private var showOptions: Bool = false
    @State private var showCopiedAlert: Bool = false

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
            // Top Header: Pin, Status Badge, Options, Close
            HStack(spacing: 8) {
                // Pin Button
                Button(action: onTogglePin) {
                    Image(systemName: note.isPinnedOnTop ? "pin.fill" : "pin.slash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(note.isPinnedOnTop ? .accentColor : note.color.secondaryTextColor)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(note.isPinnedOnTop ? "Always on Top (Active)" : "Standard Window Level")

                // Status Badge (todo, doing, done in lower case with status-colored text)
                StatusBadgeView(status: $note.status)

                Spacer()

                // Settings popover
                Button(action: { showOptions.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(note.color.secondaryTextColor)
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
                        .foregroundColor(note.color.secondaryTextColor.opacity(0.75))
                        .padding(2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Delete Sticky Note")
            }
            .padding(.horizontal, 10)
            .padding(.top, 9)
            .padding(.bottom, 4)

            // Plain text editor with smart bullet / checklist support
            CustomTextEditor(
                text: $note.text,
                font: currentNSFont,
                textColor: currentNSColor
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .opacity(0.15)
                .padding(.horizontal, 8)

            // Always Visible Bottom Footer: List controls, Font controls & Send to AI
            HStack(spacing: 8) {
                // Checklist button
                Button(action: insertChecklist) {
                    Image(systemName: "checklist")
                        .font(.system(size: 11))
                        .foregroundColor(note.color.secondaryTextColor)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Insert Checklist Item (- [ ])")

                // Bullet button
                Button(action: insertBullet) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11))
                        .foregroundColor(note.color.secondaryTextColor)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Insert Bullet (•)")

                // Font size decrement
                Button(action: {
                    if note.fontSize > 11 { note.fontSize -= 1 }
                }) {
                    Text("A-")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(note.color.secondaryTextColor)
                        .padding(2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Smaller Text")

                // Font size increment
                Button(action: {
                    if note.fontSize < 32 { note.fontSize += 1 }
                }) {
                    Text("A+")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(note.color.secondaryTextColor)
                        .padding(2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Larger Text")

                Spacer()

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
                            .font(.system(size: 9))
                        Text("Send to AI")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(note.color.textColor.opacity(0.08))
                    .foregroundColor(note.color.textColor)
                    .clipShape(Capsule())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Send Note Content to ChatGPT or Claude")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.03))
        }
        .frame(minWidth: 220, minHeight: 200)
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
            Text("Card Appearance")
                .font(.headline)
                .padding(.bottom, 2)

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
        .frame(width: 240)
    }
}
