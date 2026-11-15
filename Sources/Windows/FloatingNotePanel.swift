import AppKit
import SwiftUI

final class FloatingNotePanel: NSPanel {
    let noteId: UUID

    init(note: StickyNote, rootView: AnyView) {
        self.noteId = note.id

        // Standard borderless floating panel
        super.init(
            contentRect: NSRect(x: note.x, y: note.y, width: note.width, height: note.height),
            styleMask: [.nonactivatingPanel, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.isMovableByWindowBackground = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.minSize = NSSize(width: 180, height: 120)
        self.alphaValue = CGFloat(note.opacity)

        // Float across spaces/virtual desktops and full-screen apps
        // NOTE: .stationary was causing windows to disappear when dragged across spaces or repositioned!
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        updateLevel(isPinned: note.isPinnedOnTop)

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        self.contentView = hostingView
    }

    func updateLevel(isPinned: Bool) {
        let targetLevel: NSWindow.Level = isPinned ? .floating : .normal
        if self.level != targetLevel {
            self.level = targetLevel
            if isPinned {
                self.orderFront(nil)
            }
        }
    }

    func updateOpacity(_ opacity: Double) {
        let targetAlpha = CGFloat(max(0.2, min(1.0, opacity)))
        if abs(self.alphaValue - targetAlpha) > 0.01 {
            self.alphaValue = targetAlpha
        }
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
