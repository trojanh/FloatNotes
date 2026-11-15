import Foundation

enum NoteStatus: String, CaseIterable, Codable, Identifiable {
    case todo = "todo"
    case inProgress = "in progress"
    case done = "done"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .todo: return "todo"
        case .inProgress: return "doing"
        case .done: return "done"
        }
    }
}

enum NoteColor: String, CaseIterable, Codable, Identifiable {
    case yellow
    case white
    case graphite
    case lavender
    case mint
    case sky

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yellow: return "Warm Yellow"
        case .white: return "Frosted White"
        case .graphite: return "Graphite"
        case .lavender: return "Lavender"
        case .mint: return "Mint Green"
        case .sky: return "Sky Blue"
        }
    }
}

enum NoteFontDesign: String, CaseIterable, Codable, Identifiable {
    case standard = "Default"
    case rounded = "Rounded"
    case monospaced = "Mono"
    case serif = "Serif"

    var id: String { rawValue }
}

struct StickyNote: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Position and size
    var x: Double = 200
    var y: Double = 200
    var width: Double = 260
    var height: Double = 280
    
    // Status
    var status: NoteStatus = .todo
    
    // Customization
    var color: NoteColor = .yellow
    var fontSize: Double = 14.0
    var fontDesign: NoteFontDesign = .standard
    var opacity: Double = 0.92
    
    // State
    var isPinnedOnTop: Bool = true
    var isVisible: Bool = true
}
