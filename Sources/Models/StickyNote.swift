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

    init(
        id: UUID = UUID(),
        text: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        x: Double = 200,
        y: Double = 200,
        width: Double = 260,
        height: Double = 280,
        status: NoteStatus = .todo,
        color: NoteColor = .yellow,
        fontSize: Double = 14.0,
        fontDesign: NoteFontDesign = .standard,
        opacity: Double = 0.92,
        isPinnedOnTop: Bool = true,
        isVisible: Bool = true
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.status = status
        self.color = color
        self.fontSize = fontSize
        self.fontDesign = fontDesign
        self.opacity = opacity
        self.isPinnedOnTop = isPinnedOnTop
        self.isVisible = isVisible
    }

    enum CodingKeys: String, CodingKey {
        case id, text, createdAt, updatedAt, x, y, width, height, status, color, fontSize, fontDesign, opacity, isPinnedOnTop, isVisible
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        self.x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 200
        self.y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 200
        self.width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 260
        self.height = try container.decodeIfPresent(Double.self, forKey: .height) ?? 280
        self.status = try container.decodeIfPresent(NoteStatus.self, forKey: .status) ?? .todo
        self.color = try container.decodeIfPresent(NoteColor.self, forKey: .color) ?? .yellow
        self.fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? 14.0
        self.fontDesign = try container.decodeIfPresent(NoteFontDesign.self, forKey: .fontDesign) ?? .standard
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 0.92
        self.isPinnedOnTop = try container.decodeIfPresent(Bool.self, forKey: .isPinnedOnTop) ?? true
        self.isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
    }
}
