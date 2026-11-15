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

        setupStandardMenus()

        VisualTester.runVisualTests(store: noteStore)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    private func setupStandardMenus() {
        let mainMenu = NSMenu()

        // Application Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About Floating Notes", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Floating Notes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit Menu (crucial for ⌘A, ⌘C, ⌘V, ⌘X, ⌘Z, ⇧⌘Z)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")

        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        let redoItem = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)
        editMenu.addItem(NSMenuItem.separator())

        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenu.addItem(NSMenuItem.separator())

        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Format Menu (macOS Standard Font Size Shortcuts: ⌘+ and ⌘-)
        let formatMenuItem = NSMenuItem()
        let formatMenu = NSMenu(title: "Format")
        let fontMenuItem = NSMenuItem(title: "Font", action: nil, keyEquivalent: "")
        let fontMenu = NSMenu(title: "Font")

        let biggerItem = NSMenuItem(title: "Bigger", action: #selector(makeFontBiggerAction), keyEquivalent: "+")
        biggerItem.target = self
        fontMenu.addItem(biggerItem)

        let biggerItemEq = NSMenuItem(title: "Bigger", action: #selector(makeFontBiggerAction), keyEquivalent: "=")
        biggerItemEq.target = self
        biggerItemEq.isAlternate = true
        fontMenu.addItem(biggerItemEq)

        let smallerItem = NSMenuItem(title: "Smaller", action: #selector(makeFontSmallerAction), keyEquivalent: "-")
        smallerItem.target = self
        fontMenu.addItem(smallerItem)

        fontMenuItem.submenu = fontMenu
        formatMenu.addItem(fontMenuItem)
        formatMenuItem.submenu = formatMenu
        mainMenu.addItem(formatMenuItem)

        // Window Menu (⌘W, ⌘M)
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func makeFontBiggerAction() {
        WindowManager.shared.adjustFontSizeForActiveNote(delta: 1)
    }

    @objc private func makeFontSmallerAction() {
        WindowManager.shared.adjustFontSizeForActiveNote(delta: -1)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
