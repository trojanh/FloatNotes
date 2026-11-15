import AppKit
import SwiftUI

final class FloatingNotePanel: NSPanel {
    let noteId: UUID

    init(note: StickyNote, rootView: AnyView) {
        self.noteId = note.id

        // Borderless, non-activating panel that supports smooth dragging and controls
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
        self.minSize = NSSize(width: 180, height: 180)

        // Float across spaces/virtual desktops and full-screen apps
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
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

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
