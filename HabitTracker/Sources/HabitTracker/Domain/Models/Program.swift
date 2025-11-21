import Foundation

/// A pre-defined program or template that users can adopt
///
/// Programs are curated collections of goals and habits designed by experts or the community.
/// Examples: "Morning Routine", "Fitness Beginner", "Productivity Boost"
///
/// **Database Schema Match:** This model now accurately reflects the `programs` table schema.
@Observable
public final class Program: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var slug: String?
    public var title: String
    public var summary: String?
    public var richText: RichTextContent?
    public var category: String?
    public var tags: [String]
    public var thumbnailURL: String?
    public var heroURL: String?
    public var wideURL: String?
    public var ratingAvg: Double?
    public var addedCount: Int
    public var visibility: ProgramVisibility
    public let createdAt: Date
    public var updatedAt: Date

    /// MARK: - Initialization

    public init(
        id: UUID = UUID(),
        slug: String? = nil,
        title: String,
        summary: String? = nil,
        richText: RichTextContent? = nil,
        category: String? = nil,
        tags: [String] = [],
        thumbnailURL: String? = nil,
        heroURL: String? = nil,
        wideURL: String? = nil,
        ratingAvg: Double? = nil,
        addedCount: Int = 0,
        visibility: ProgramVisibility = .public,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.summary = summary
        self.richText = richText
        self.category = category
        self.tags = tags
        self.thumbnailURL = thumbnailURL
        self.heroURL = heroURL
        self.wideURL = wideURL
        self.ratingAvg = ratingAvg
        self.addedCount = addedCount
        self.visibility = visibility
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// MARK: - Computed Properties

    /// Display name for the program
    public var displayName: String {
        title
    }

    /// Whether the program is publicly visible
    public var isPublic: Bool {
        visibility == .public
    }

    /// Returns the best available image URL (hero > wide > thumbnail)
    public var bestImageURL: String? {
        heroURL ?? wideURL ?? thumbnailURL
    }

    /// Formatted rating for display
    public var formattedRating: String? {
        guard let rating = ratingAvg else { return nil }
        return String(format: "%.1f", rating)
    }

    /// MARK: - Equatable

    public static func == (lhs: Program, rhs: Program) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.category == rhs.category
    }

    /// MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// MARK: - RichTextContent

/// Rich text content stored as JSONB in database
///
/// This represents structured content with blocks (paragraphs, headings, lists, etc.)
public struct RichTextContent: Codable, Sendable, Equatable {
    public let blocks: [Block]

    public init(blocks: [Block] = []) {
        self.blocks = blocks
    }

    public struct Block: Codable, Sendable, Equatable {
        public let type: String
        public let content: String?
        public let data: [String: AnyCodable]?

        public init(type: String, content: String? = nil, data: [String: AnyCodable]? = nil) {
            self.type = type
            self.content = content
            self.data = data
        }
    }
}

/// Helper type for encoding/decoding Any values in JSON
public struct AnyCodable: Codable, Sendable, Equatable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if container.decodeNil() {
            value = Optional<Any>.none as Any
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        default:
            try container.encodeNil()
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as String, let r as String): return l == r
        case (let l as Bool, let r as Bool): return l == r
        default: return false
        }
    }
}

/// MARK: - ProgramVisibility

/// Program visibility levels matching database enum
public enum ProgramVisibility: String, Codable, Sendable, CaseIterable {
    case `public` = "public"
    case unlisted = "unlisted"
    case `private` = "private"

    public var displayName: String {
        switch self {
        case .public: return "Public"
        case .unlisted: return "Unlisted"
        case .private: return "Private"
        }
    }

    public var isPublic: Bool {
        self == .public
    }
}

/// MARK: - ProgramGoal (formerly ProgramItem in database: program_items)

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
    public var linkedExerciseKey: String?
    public var defaultPoints: Int
    public var orderIndex: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        programId: UUID,
        title: String,
        emoji: String? = nil,
        kind: String,
        linkedExerciseKey: String? = nil,
        defaultPoints: Int = 5,
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.programId = programId
        self.title = title
        self.emoji = emoji
        self.kind = kind
        self.linkedExerciseKey = linkedExerciseKey
        self.defaultPoints = defaultPoints
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
