import SwiftUI

struct StatusBadgeView: View {
    @Binding var status: NoteStatus
    @State private var showMenu: Bool = false

    var badgeColor: Color {
        switch status {
        case .todo:
            return Color(red: 0.96, green: 0.55, blue: 0.12) // warm amber orange
        case .inProgress:
            return Color(red: 0.18, green: 0.52, blue: 0.95) // vibrant blue
        case .done:
            return Color(red: 0.15, green: 0.68, blue: 0.38) // emerald green
        }
    }

    var body: some View {
        Button(action: {
            showMenu.toggle()
        }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 6, height: 6)
                Text(status.shortLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(badgeColor)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(badgeColor.opacity(0.8))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.14))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(badgeColor.opacity(0.35), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showMenu, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(NoteStatus.allCases) { s in
                    Button(action: {
                        status = s
                        showMenu = false
                    }) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(color(for: s))
                                .frame(width: 7, height: 7)
                            Text(s.shortLabel)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(color(for: s))
                            Spacer()
                            if status == s {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(color(for: s))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .frame(width: 120)
        }
        .help("Note Status: Click to change")
    }

    private func color(for s: NoteStatus) -> Color {
        switch s {
        case .todo: return Color(red: 0.96, green: 0.55, blue: 0.12)
        case .inProgress: return Color(red: 0.18, green: 0.52, blue: 0.95)
        case .done: return Color(red: 0.15, green: 0.68, blue: 0.38)
        }
    }
}
