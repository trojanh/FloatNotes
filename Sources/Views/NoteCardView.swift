import SwiftUI
import AppKit

struct NoteCardView: View {
    @Binding var note: StickyNote
    var onDelete: () -> Void
    var onTogglePin: () -> Void

    @State private var isHovered: Bool = false
    @State private var showOptions: Bool = false

    var currentFont: Font {
        let size = CGFloat(note.fontSize)
        switch note.fontDesign {
        case .standard:
            return .system(size: size, weight: .regular, design: .default)
        case .rounded:
            return .system(size: size, weight: .regular, design: .rounded)
        case .monospaced:
            return .system(size: size, weight: .regular, design: .monospaced)
        case .serif:
            return .system(size: size, weight: .regular, design: .serif)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header bar (shows actions on hover or tap)
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
                .help(note.isPinnedOnTop ? "Float on Top (Active)" : "Standard Window Level")

                Spacer()

                // Font size quick controls
                if isHovered || showOptions {
                    HStack(spacing: 4) {
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
                    }

                    // Options popover button
                    Button(action: { showOptions.toggle() }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 12))
                            .foregroundColor(note.color.secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showOptions, arrowEdge: .bottom) {
                        noteCustomizationPopover
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
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(Color.clear)

            // Plain text editor
            TextEditor(text: $note.text)
                .font(currentFont)
                .foregroundColor(note.color.textColor)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 180, minHeight: 180)
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

    private var noteCustomizationPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Customize Card")
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
        .frame(width: 230)
    }
}
