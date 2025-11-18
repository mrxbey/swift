import Foundation

/// A pre-defined program or template that users can adopt
///
/// Programs are curated collections of goals and habits designed by experts or the community.
/// Examples: "Morning Routine", "Fitness Beginner", "Productivity Boost"
@Observable
public final class Program: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var title: String
    public var description: String
    public var emoji: String?
    public var imageURL: String?
    public var category: ProgramCategory
    public var difficulty: ProgramDifficulty
    public var durationDays: Int?
    public var tags: [String]
    public var authorName: String?
    public var isOfficial: Bool
    public var isPublished: Bool
    public let createdAt: Date
    public var updatedAt: Date

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        emoji: String? = nil,
        imageURL: String? = nil,
        category: ProgramCategory,
        difficulty: ProgramDifficulty = .beginner,
        durationDays: Int? = nil,
        tags: [String] = [],
        authorName: String? = nil,
        isOfficial: Bool = false,
        isPublished: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.emoji = emoji
        self.imageURL = imageURL
        self.category = category
        self.difficulty = difficulty
        self.durationDays = durationDays
        self.tags = tags
        self.authorName = authorName
        self.isOfficial = isOfficial
        self.isPublished = isPublished
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Display name with emoji if available
    public var displayName: String {
        if let emoji = emoji {
            return "\(emoji) \(title)"
        }
        return title
    }

    /// Formatted duration for display
    public var formattedDuration: String? {
        guard let days = durationDays else { return nil }

        if days < 7 {
            return "\(days) days"
        } else if days % 7 == 0 {
            let weeks = days / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let weeks = days / 7
            let remainingDays = days % 7
            return "\(weeks)w \(remainingDays)d"
        }
    }

    // MARK: - Equatable

    public static func == (lhs: Program, rhs: Program) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.category == rhs.category
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ProgramCategory

/// Program categories for organization
public enum ProgramCategory: String, Codable, Sendable, CaseIterable {
    case health = "health"
    case fitness = "fitness"
    case productivity = "productivity"
    case mindfulness = "mindfulness"
    case learning = "learning"
    case creativity = "creativity"
    case social = "social"
    case finance = "finance"

    public var displayName: String {
        rawValue.capitalized
    }

    public var emoji: String {
        switch self {
        case .health: return "🏥"
        case .fitness: return "💪"
        case .productivity: return "⚡"
        case .mindfulness: return "🧘"
        case .learning: return "📚"
        case .creativity: return "🎨"
        case .social: return "👥"
        case .finance: return "💰"
        }
    }
}

// MARK: - ProgramDifficulty

/// Program difficulty levels
public enum ProgramDifficulty: String, Codable, Sendable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    public var displayName: String {
        rawValue.capitalized
    }

    public var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .intermediate: return "🌿"
        case .advanced: return "🌳"
        }
    }
}

// MARK: - ProgramGoal

/// A goal template within a program
///
/// When a user adopts a program, these templates are used to create actual goals.
@Observable
public final class ProgramGoal: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let programId: UUID
    public var title: String
    public var emoji: String?
    public var kind: String
    public var timesPerDay: Int
    public var schedulePattern: String?
    public var orderIndex: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        programId: UUID,
        title: String,
        emoji: String? = nil,
        kind: String,
        timesPerDay: Int = 1,
        schedulePattern: String? = nil,
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.programId = programId
        self.title = title
        self.emoji = emoji
        self.kind = kind
        self.timesPerDay = timesPerDay
        self.schedulePattern = schedulePattern
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static func == (lhs: ProgramGoal, rhs: ProgramGoal) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
