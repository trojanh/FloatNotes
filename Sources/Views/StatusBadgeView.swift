import SwiftUI

struct StatusBadgeView: View {
    @Binding var status: NoteStatus
    @State private var showMenu: Bool = false

    var badgeColor: Color {
        switch status {
        case .todo:
            return Color(red: 0.98, green: 0.58, blue: 0.16) // warm amber orange
        case .inProgress:
            return Color(red: 0.22, green: 0.58, blue: 0.98) // vibrant blue
        case .done:
            return Color(red: 0.20, green: 0.72, blue: 0.42) // emerald green
        }
    }

    var body: some View {
        Button(action: {
            showMenu.toggle()
        }) {
            HStack(spacing: 5) {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: badgeColor.opacity(0.6), radius: 3, x: 0, y: 0)

                Text(status.shortLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(badgeColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(badgeColor.opacity(0.75))
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(
                ZStack {
                    badgeColor.opacity(0.12)
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.clear],
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
                            colors: [Color.white.opacity(0.4), badgeColor.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showMenu, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(NoteStatus.allCases) { s in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            status = s
                        }
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
        case .todo: return Color(red: 0.98, green: 0.58, blue: 0.16)
        case .inProgress: return Color(red: 0.22, green: 0.58, blue: 0.98)
        case .done: return Color(red: 0.20, green: 0.72, blue: 0.42)
        }
    }
}
