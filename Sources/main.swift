import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var noteStore: NoteStore!
    private var statusBarController: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as an accessory app (no dock icon, pure menu-bar + floating panels)
        NSApp.setActivationPolicy(.accessory)

        self.noteStore = NoteStore()
        WindowManager.shared.configure(with: noteStore)
        self.statusBarController = StatusBarController(noteStore: noteStore)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
