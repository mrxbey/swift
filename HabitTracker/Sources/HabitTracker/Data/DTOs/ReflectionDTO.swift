import Foundation

/// Data Transfer Object for Reflection entity
///
/// Maps between the PostgreSQL `reflections` table (snake_case) and the Swift `Reflection` domain model (camelCase).
public struct ReflectionDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let goalId: UUID?
    public let areaId: UUID?
    public let content: String
    public let tags: [String]
    public let mood: String?
    public let reflectionDate: Date
    public let createdAt: Date
    public let updatedAt: Date

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case goalId = "goal_id"
        case areaId = "area_id"
        case content
        case tags
        case mood
        case reflectionDate = "reflection_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initialization

    /// Creates a DTO from a domain model
    ///
    /// - Parameter reflection: The domain Reflection model
    public init(from reflection: Reflection) {
        self.id = reflection.id
        self.userId = reflection.userId
        self.goalId = reflection.goalId
        self.areaId = reflection.areaId
        self.content = reflection.content
        self.tags = reflection.tags
        self.mood = reflection.mood?.rawValue
        self.reflectionDate = reflection.reflectionDate
        self.createdAt = reflection.createdAt
        self.updatedAt = reflection.updatedAt
    }

    // MARK: - Conversion

    /// Converts the DTO to a domain model
    public var toDomain: Reflection {
        Reflection(
            id: id,
            userId: userId,
            goalId: goalId,
            areaId: areaId,
            content: content,
            tags: tags,
            mood: mood.flatMap { ReflectionMood(rawValue: $0) },
            reflectionDate: reflectionDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
