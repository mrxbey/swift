import Foundation

/// Data Transfer Object for Program entity
///
/// Maps between the PostgreSQL `programs` table (snake_case) and the Swift `Program` domain model (camelCase).
public struct ProgramDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let description: String
    public let emoji: String?
    public let imageURL: String?
    public let category: String
    public let difficulty: String
    public let durationDays: Int?
    public let tags: [String]
    public let authorName: String?
    public let isOfficial: Bool
    public let isPublished: Bool
    public let createdAt: Date
    public let updatedAt: Date

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case emoji
        case imageURL = "image_url"
        case category
        case difficulty
        case durationDays = "duration_days"
        case tags
        case authorName = "author_name"
        case isOfficial = "is_official"
        case isPublished = "is_published"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initialization

    /// Creates a DTO from a domain model
    ///
    /// - Parameter program: The domain Program model
    public init(from program: Program) {
        self.id = program.id
        self.title = program.title
        self.description = program.description
        self.emoji = program.emoji
        self.imageURL = program.imageURL
        self.category = program.category.rawValue
        self.difficulty = program.difficulty.rawValue
        self.durationDays = program.durationDays
        self.tags = program.tags
        self.authorName = program.authorName
        self.isOfficial = program.isOfficial
        self.isPublished = program.isPublished
        self.createdAt = program.createdAt
        self.updatedAt = program.updatedAt
    }

    // MARK: - Conversion

    /// Converts the DTO to a domain model
    public var toDomain: Program {
        Program(
            id: id,
            title: title,
            description: description,
            emoji: emoji,
            imageURL: imageURL,
            category: ProgramCategory(rawValue: category) ?? .productivity,
            difficulty: ProgramDifficulty(rawValue: difficulty) ?? .beginner,
            durationDays: durationDays,
            tags: tags,
            authorName: authorName,
            isOfficial: isOfficial,
            isPublished: isPublished,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - ProgramGoalDTO

/// Data Transfer Object for ProgramGoal entity
///
/// Maps between the PostgreSQL `program_goals` table and the Swift domain model.
public struct ProgramGoalDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let programId: UUID
    public let title: String
    public let emoji: String?
    public let kind: String
    public let timesPerDay: Int
    public let schedulePattern: String?
    public let orderIndex: Int
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case title
        case emoji
        case kind
        case timesPerDay = "times_per_day"
        case schedulePattern = "schedule_pattern"
        case orderIndex = "order_index"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from programGoal: ProgramGoal) {
        self.id = programGoal.id
        self.programId = programGoal.programId
        self.title = programGoal.title
        self.emoji = programGoal.emoji
        self.kind = programGoal.kind
        self.timesPerDay = programGoal.timesPerDay
        self.schedulePattern = programGoal.schedulePattern
        self.orderIndex = programGoal.orderIndex
        self.createdAt = programGoal.createdAt
        self.updatedAt = programGoal.updatedAt
    }

    public var toDomain: ProgramGoal {
        ProgramGoal(
            id: id,
            programId: programId,
            title: title,
            emoji: emoji,
            kind: kind,
            timesPerDay: timesPerDay,
            schedulePattern: schedulePattern,
            orderIndex: orderIndex,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
