import SwiftUI

struct StatusBadgeView: View {
    @Binding var status: NoteStatus

    var badgeColor: Color {
        switch status {
        case .todo:
            return Color.orange
        case .inProgress:
            return Color.blue
        case .done:
            return Color.green
        }
    }

    var body: some View {
        Menu {
            ForEach(NoteStatus.allCases) { s in
                Button(action: {
                    status = s
                }) {
                    HStack {
                        Text(s.rawValue)
                        if status == s {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 3) {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 6, height: 6)
                Text(status.shortLabel)
                    .font(.system(size: 9, weight: .bold))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(badgeColor.opacity(0.18))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(badgeColor.opacity(0.4), lineWidth: 0.5)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Note Status: Click to change")
    }
}
