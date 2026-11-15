import AppKit
import Combine

enum AIDestination: String, CaseIterable, Codable, Identifiable {
    case automatic = "auto"
    case desktopApp = "app"
    case webBrowser = "web"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "Auto (App if installed, else Web)"
        case .desktopApp: return "Desktop App only"
        case .webBrowser: return "Web Browser only"
        }
    }
}

final class AIService: ObservableObject {
    static let shared = AIService()

    @Published var preferredDestination: AIDestination = .automatic {
        didSet {
            UserDefaults.standard.set(preferredDestination.rawValue, forKey: "AIPreferredDestination")
        }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "AIPreferredDestination"),
           let dest = AIDestination(rawValue: saved) {
            self.preferredDestination = dest
        }
    }

    static let chatGPTAppScheme = "chatgpt://"
    static let claudeAppScheme = "claude://"

    static var isChatGPTAppInstalled: Bool {
        if let url = URL(string: chatGPTAppScheme),
           NSWorkspace.shared.urlForApplication(toOpen: url) != nil {
            return true
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.chat") != nil
    }

    static var isClaudeAppInstalled: Bool {
        if let url = URL(string: claudeAppScheme),
           NSWorkspace.shared.urlForApplication(toOpen: url) != nil {
            return true
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.anthropic.claudefordesktop") != nil
    }

    static func sendToChatGPT(text: String, destination: AIDestination? = nil) {
        copyToClipboard(text: text)
        let mode = destination ?? shared.preferredDestination

        if mode == .desktopApp || (mode == .automatic && isChatGPTAppInstalled) {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.chat") {
                NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
                return
            } else if let schemeURL = URL(string: chatGPTAppScheme),
                      NSWorkspace.shared.urlForApplication(toOpen: schemeURL) != nil {
                NSWorkspace.shared.open(schemeURL)
                return
            }
        }

        // Open Web
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let webURL = URL(string: "https://chatgpt.com/?q=\(encoded)") {
            NSWorkspace.shared.open(webURL)
        }
    }

    static func sendToClaude(text: String, destination: AIDestination? = nil) {
        copyToClipboard(text: text)
        let mode = destination ?? shared.preferredDestination

        if mode == .desktopApp || (mode == .automatic && isClaudeAppInstalled) {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.anthropic.claudefordesktop") {
                NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
                return
            } else if let schemeURL = URL(string: claudeAppScheme),
                      NSWorkspace.shared.urlForApplication(toOpen: schemeURL) != nil {
                NSWorkspace.shared.open(schemeURL)
                return
            }
        }

        // Open Web
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let target = encoded.isEmpty ? "https://claude.ai/new" : "https://claude.ai/new?q=\(encoded)"
        if let webURL = URL(string: target) {
            NSWorkspace.shared.open(webURL)
        }
    }

    private static func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
