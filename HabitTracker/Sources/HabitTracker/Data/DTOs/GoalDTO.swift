import Foundation

/// Data Transfer Object for Goal entity
///
/// Maps between the PostgreSQL `goals` table (snake_case) and the Swift `Goal` domain model (camelCase).
public struct GoalDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let areaId: UUID
    public let title: String
    public let emoji: String?
    public let kind: String
    public let status: String
    public let keepUntilComplete: Bool
    public let timesPerDay: Int
    public let pointsPerCompletion: Int
    public let linkedExerciseKey: String?
    public let hashtags: [String]
    public let createdAt: Date
    public let updatedAt: Date

    /// MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case areaId = "area_id"
        case title
        case emoji
        case kind
        case status
        case keepUntilComplete = "keep_until_complete"
        case timesPerDay = "times_per_day"
        case pointsPerCompletion = "points_per_completion"
        case linkedExerciseKey = "linked_exercise_key"
        case hashtags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// MARK: - Initialization

    /// Creates a DTO from a domain model
    ///
    /// - Parameter goal: The domain Goal model
    public init(from goal: Goal) {
        self.id = goal.id
        self.userId = goal.userId
        self.areaId = goal.areaId
        self.title = goal.title
        self.emoji = goal.emoji
        self.kind = goal.kind.rawValue
        self.status = goal.status.rawValue
        self.keepUntilComplete = goal.keepUntilComplete
        self.timesPerDay = goal.timesPerDay
        self.pointsPerCompletion = goal.pointsPerCompletion
        self.linkedExerciseKey = goal.linkedExerciseKey?.rawValue
        self.hashtags = goal.hashtags
        self.createdAt = goal.createdAt
        self.updatedAt = goal.updatedAt
    }

    /// MARK: - Conversion

    /// Converts the DTO to a domain model
    public var toDomain: Goal {
        Goal(
            id: id,
            userId: userId,
            areaId: areaId,
            title: title,
            emoji: emoji,
            kind: GoalKind(rawValue: kind) ?? .habit,
            status: GoalStatus(rawValue: status) ?? .active,
            keepUntilComplete: keepUntilComplete,
            timesPerDay: timesPerDay,
            pointsPerCompletion: pointsPerCompletion,
            linkedExerciseKey: linkedExerciseKey.flatMap { LinkedExercise(rawValue: $0) },
            hashtags: hashtags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
