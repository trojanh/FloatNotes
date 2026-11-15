import SwiftUI
import AppKit

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
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

// Glass Card Container with frosted blur, specular rim lights, and soft multi-stop shadow
struct GlassContainer<Content: View>: View {
    var cornerRadius: CGFloat = 20
    var tintColor: Color = .clear
    var tintOpacity: Double = 0.35
    var content: () -> Content

    init(cornerRadius: CGFloat = 20, tintColor: Color = .clear, tintOpacity: Double = 0.35, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.tintOpacity = tintOpacity
        self.content = content
    }

    var body: some View {
        content()
            .background(
                ZStack {
                    // Deep frosted glass vibrancy
                    VisualEffectBackground(material: .popover, blendingMode: .behindWindow)

                    // Subtle ambient tint wash
                    tintColor
                        .opacity(tintOpacity)

                    // Top-to-bottom specular glass reflection gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.04),
                            Color.black.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // Double specular border (Apple glass edge effect)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.65),
                                Color.white.opacity(0.20),
                                Color.black.opacity(0.12),
                                Color.white.opacity(0.35)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
    }
}

extension NoteColor {
    // Modernized Pastel Glass Color Palette
    var swiftUIColor: Color {
        switch self {
        case .yellow:
            return Color(red: 1.0, green: 0.88, blue: 0.45)
        case .white:
            return Color(red: 0.96, green: 0.97, blue: 0.99)
        case .graphite:
            return Color(red: 0.16, green: 0.17, blue: 0.20)
        case .lavender:
            return Color(red: 0.85, green: 0.78, blue: 0.96)
        case .mint:
            return Color(red: 0.70, green: 0.94, blue: 0.82)
        case .sky:
            return Color(red: 0.72, green: 0.88, blue: 0.99)
        }
    }

    var textColor: Color {
        switch self {
        case .graphite:
            return Color.white.opacity(0.96)
        default:
            return Color(red: 0.12, green: 0.13, blue: 0.16)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .graphite:
            return Color.white.opacity(0.65)
        default:
            return Color.black.opacity(0.50)
        }
    }
}
