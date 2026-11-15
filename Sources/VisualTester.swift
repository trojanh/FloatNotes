import AppKit
import SwiftUI

final class VisualTester {
    static func runVisualTests(store: NoteStore) {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--visual-test") else { return }

        print("[VisualTester] Running visual tests on main thread...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // 1. Show All Notes Window
            WindowManager.shared.showAllNotesWindow()
            NSApp.activate(ignoringOtherApps: true)
            print("[VisualTester] AllNotesWindow shown. Policy is: \(NSApp.activationPolicy() == .regular ? "regular" : "accessory")")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                // Find AllNotesWindow and capture directly using window image API
                captureAppWindows(store: store)
            }
        }
    }

    static func captureAppWindows(store: NoteStore) {
        let scratchDir = "/Users/rajantiwari/.gemini/antigravity/brain/27b9b0b4-153a-4b42-a099-3ffa847dc623/scratch"
        
        for window in NSApp.windows {
            guard window.isVisible, let contentView = window.contentView else { continue }
            let bounds = contentView.bounds
            guard let bitmap = contentView.bitmapImageRepForCachingDisplay(in: bounds) else { continue }
            contentView.cacheDisplay(in: bounds, to: bitmap)

            let isAllNotes = window.frame.width > 500
            let name = isAllNotes ? "all_notes_window_view" : "floating_note_card_view"
            let fileURL = URL(fileURLWithPath: "\(scratchDir)/\(name).png")

            if let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: fileURL)
                print("[VisualTester] Saved window capture to \(fileURL.path)")
            }
        }

        // Test 2: Realtime resize
        print("[VisualTester] Testing realtime resize to 320x220...")
        store.defaultNoteWidth = 320
        store.defaultNoteHeight = 220
        WindowManager.shared.updateNoteSize(width: 320, height: 220)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            for window in NSApp.windows where window.frame.width <= 500 && window.isVisible {
                if let contentView = window.contentView,
                   let bitmap = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds) {
                    contentView.cacheDisplay(in: contentView.bounds, to: bitmap)
                    let fileURL = URL(fileURLWithPath: "\(scratchDir)/floating_note_after_realtime_resize.png")
                    if let pngData = bitmap.representation(using: .png, properties: [:]) {
                        try? pngData.write(to: fileURL)
                        print("[VisualTester] Saved resized note capture to \(fileURL.path)")
                    }
                }
            }
            print("[VisualTester] Direct in-memory visual verification complete!")
            exit(0)
        }
    }
}
