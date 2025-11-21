import Foundation

/// Data Transfer Object for Program entity
///
/// Maps between the PostgreSQL `programs` table (snake_case) and the Swift `Program` domain model (camelCase).
public struct ProgramDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let slug: String?
    public let title: String
    public let summary: String?
    public let richText: RichTextDTO?
    public let category: String?
    public let tags: [String]
    public let thumbnailURL: String?
    public let heroURL: String?
    public let wideURL: String?
    public let ratingAvg: Double?
    public let addedCount: Int
    public let visibility: String
    public let createdAt: Date
    public let updatedAt: Date

    /// MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case title
        case summary
        case richText = "rich_text"
        case category
        case tags
        case thumbnailURL = "thumbnail_url"
        case heroURL = "hero_url"
        case wideURL = "wide_url"
        case ratingAvg = "rating_avg"
        case addedCount = "added_count"
        case visibility
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// MARK: - Initialization

    /// Creates a DTO from a domain model
    ///
    /// - Parameter program: The domain Program model
    public init(from program: Program) {
        self.id = program.id
        self.slug = program.slug
        self.title = program.title
        self.summary = program.summary
        self.richText = program.richText.map { RichTextDTO(from: $0) }
        self.category = program.category
        self.tags = program.tags
        self.thumbnailURL = program.thumbnailURL
        self.heroURL = program.heroURL
        self.wideURL = program.wideURL
        self.ratingAvg = program.ratingAvg
        self.addedCount = program.addedCount
        self.visibility = program.visibility.rawValue
        self.createdAt = program.createdAt
        self.updatedAt = program.updatedAt
    }

    /// MARK: - Conversion

    /// Converts the DTO to a domain model
    public var toDomain: Program {
        Program(
            id: id,
            slug: slug,
            title: title,
            summary: summary,
            richText: richText?.toDomain,
            category: category,
            tags: tags,
            thumbnailURL: thumbnailURL,
            heroURL: heroURL,
            wideURL: wideURL,
            ratingAvg: ratingAvg,
            addedCount: addedCount,
            visibility: ProgramVisibility(rawValue: visibility) ?? .public,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// MARK: - RichTextDTO

/// DTO for rich text JSONB content
public struct RichTextDTO: Codable, Sendable, Equatable {
    public let blocks: [BlockDTO]

    public init(blocks: [BlockDTO] = []) {
        self.blocks = blocks
    }

    public init(from richText: RichTextContent) {
        self.blocks = richText.blocks.map { BlockDTO(from: $0) }
    }

    public var toDomain: RichTextContent {
        RichTextContent(blocks: blocks.map { $0.toDomain })
    }

    public struct BlockDTO: Codable, Sendable, Equatable {
        public let type: String
        public let content: String?
        public let data: [String: AnyCodableDTO]?

        public init(type: String, content: String? = nil, data: [String: AnyCodableDTO]? = nil) {
            self.type = type
            self.content = content
            self.data = data
        }

        public init(from block: RichTextContent.Block) {
            self.type = block.type
            self.content = block.content
            self.data = block.data?.mapValues { AnyCodableDTO(from: $0) }
        }

        public var toDomain: RichTextContent.Block {
            RichTextContent.Block(
                type: type,
                content: content,
                data: data?.mapValues { $0.toDomain }
            )
        }
    }

    public struct AnyCodableDTO: Codable, Sendable, Equatable {
        public let value: AnyCodable

        public init(from anycodable: AnyCodable) {
            self.value = anycodable
        }

        public var toDomain: AnyCodable {
            value
        }

        public init(from decoder: Decoder) throws {
            self.value = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: Encoder) throws {
            try value.encode(to: encoder)
        }

        public static func == (lhs: AnyCodableDTO, rhs: AnyCodableDTO) -> Bool {
            lhs.value == rhs.value
        }
    }
}

/// MARK: - ProgramGoalDTO (formerly ProgramItemDTO)

/// Data Transfer Object for ProgramGoal entity
///
/// Maps between the PostgreSQL `program_items` table and the Swift domain model.
public struct ProgramGoalDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let programId: UUID
    public let title: String
    public let emoji: String?
    public let kind: String
    public let linkedExerciseKey: String?
    public let defaultPoints: Int
    public let schedule: [String: AnyCodable]  // JSONB schedule configuration
    public let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case title
        case emoji
        case kind
        case linkedExerciseKey = "linked_exercise_key"
        case defaultPoints = "default_points"
        case schedule
        case orderIndex = "order_index"
    }

    public init(from programGoal: ProgramGoal) {
        self.id = programGoal.id
        self.programId = programGoal.programId
        self.title = programGoal.title
        self.emoji = programGoal.emoji
        self.kind = programGoal.kind
        self.linkedExerciseKey = programGoal.linkedExerciseKey
        self.defaultPoints = programGoal.defaultPoints
        self.schedule = programGoal.schedule
        self.orderIndex = programGoal.orderIndex
    }

    public var toDomain: ProgramGoal {
        ProgramGoal(
            id: id,
            programId: programId,
            title: title,
            emoji: emoji,
            kind: kind,
            linkedExerciseKey: linkedExerciseKey,
            defaultPoints: defaultPoints,
            schedule: schedule,
            orderIndex: orderIndex
        )
    }
}
