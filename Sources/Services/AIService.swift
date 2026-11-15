import AppKit

struct AIService {
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

    static func sendToChatGPT(text: String) {
        copyToClipboard(text: text)
        
        // 1. Try native macOS app scheme
        if isChatGPTAppInstalled {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.chat") {
                NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
                return
            }
        }
        
        // 2. Fallback to web app with pre-filled query or copied text
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let webURL = URL(string: "https://chatgpt.com/?q=\(encoded)") {
            NSWorkspace.shared.open(webURL)
        }
    }

    static func sendToClaude(text: String) {
        copyToClipboard(text: text)
        
        // 1. Try native desktop app
        if isClaudeAppInstalled {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.anthropic.claudefordesktop") {
                NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
                return
            }
        }
        
        // 2. Fallback to web app
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
