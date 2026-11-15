import Foundation

struct SmartCategorizationService {
    struct Suggestion {
        let status: NoteStatus?
        let color: NoteColor?
        let tagDescription: String
    }

    /// Analyze text to suggest suitable status, color theme, and tags
    static func analyze(text: String) -> Suggestion? {
        let lower = text.lowercased()

        // 1. Code / Bug / Tech snippet -> Graphite theme
        let codeKeywords = ["func ", "def ", "class ", "import ", "const ", "let ", "var ", "return ", "http", "api", "error:", "exception", "null", "undefined", "git ", "ssh", "curl"]
        if codeKeywords.contains(where: { lower.contains($0) }) {
            return Suggestion(status: nil, color: .graphite, tagDescription: "Code / Technical Note (Graphite)")
        }

        // 2. Urgent / High Priority Todo -> Warm Yellow + Todo
        let urgentKeywords = ["urgent", "asap", "deadline", "due today", "priority", "important", "must do", "todo:"]
        if urgentKeywords.contains(where: { lower.contains($0) }) {
            return Suggestion(status: .todo, color: .yellow, tagDescription: "High Priority Task (Warm Yellow)")
        }

        // 3. Active in-progress tasks -> Doing + Sky Blue
        let doingKeywords = ["working on", "in progress", "investigating", "ongoing", "drafting", "building", "developing"]
        if doingKeywords.contains(where: { lower.contains($0) }) {
            return Suggestion(status: .inProgress, color: .sky, tagDescription: "Active In-Progress (Sky Blue)")
        }

        // 4. Completed / Done tasks -> Done + Mint Green
        let doneKeywords = ["completed", "shipped", "finished", "deployed", "merged", "fixed", "done with"]
        if doneKeywords.contains(where: { lower.contains($0) }) {
            return Suggestion(status: .done, color: .mint, tagDescription: "Completed (Mint Green)")
        }

        // 5. Creative / Ideas / Brainstorming -> Lavender
        let ideaKeywords = ["idea:", "brainstorm", "concept", "feature request", "inspiration", "design:"]
        if ideaKeywords.contains(where: { lower.contains($0) }) {
            return Suggestion(status: nil, color: .lavender, tagDescription: "Creative Idea (Lavender)")
        }

        return nil
    }
}
