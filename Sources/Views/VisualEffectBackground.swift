import SwiftUI
import AppKit

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

extension NoteColor {
    var swiftUIColor: Color {
        switch self {
        case .yellow:
            return Color(red: 1.0, green: 0.94, blue: 0.60)
        case .white:
            return Color(red: 0.98, green: 0.98, blue: 0.99)
        case .graphite:
            return Color(red: 0.22, green: 0.22, blue: 0.24)
        case .lavender:
            return Color(red: 0.91, green: 0.86, blue: 0.98)
        case .mint:
            return Color(red: 0.82, green: 0.96, blue: 0.88)
        case .sky:
            return Color(red: 0.83, green: 0.92, blue: 0.99)
        }
    }

    var textColor: Color {
        switch self {
        case .graphite:
            return Color.white.opacity(0.95)
        default:
            return Color(red: 0.15, green: 0.15, blue: 0.17)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .graphite:
            return Color.white.opacity(0.65)
        default:
            return Color.black.opacity(0.55)
        }
    }
}
