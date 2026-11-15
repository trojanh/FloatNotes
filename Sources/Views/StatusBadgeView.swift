import SwiftUI

struct StatusBadgeView: View {
    @Binding var status: NoteStatus

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
        Menu {
            ForEach(NoteStatus.allCases) { s in
                Button(action: {
                    status = s
                }) {
                    HStack {
                        Text(s.shortLabel)
                        if status == s {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 6, height: 6)
                Text(status.shortLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(badgeColor)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(badgeColor.opacity(0.7))
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
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Note Status: Click to change")
    }
}
