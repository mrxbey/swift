import Foundation

/// Data Transfer Object for GoalOccurrence entity
///
/// Maps between the PostgreSQL `goal_occurrences` table (snake_case) and the Swift `GoalOccurrence` domain model (camelCase).
public struct GoalOccurrenceDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let goalId: UUID
    public let scheduleId: UUID?
    public let scheduledDate: Date
    public let dueAt: Date?
    public let targetCount: Int
    public let completedCount: Int
    public let status: String
    public let keepUntilComplete: Bool
    public let rolledFromId: UUID?
    public let rolledIntoId: UUID?
    public let nameOverride: String?
    public let emojiOverride: String?
    public let contentSnapshot: ContentSnapshotDTO?
    public let isOneTime: Bool
    public let createdAt: Date
    public let updatedAt: Date

    /// MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case goalId = "goal_id"
        case scheduleId = "schedule_id"
        case scheduledDate = "scheduled_date"
        case dueAt = "due_at"
        case targetCount = "target_count"
        case completedCount = "completed_count"
        case status
        case keepUntilComplete = "keep_until_complete"
        case rolledFromId = "rolled_from_id"
        case rolledIntoId = "rolled_into_id"
        case nameOverride = "name_override"
        case emojiOverride = "emoji_override"
        case contentSnapshot = "content_snapshot"
        case isOneTime = "is_one_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// MARK: - Initialization

    /// Creates a DTO from a domain model
    ///
    /// - Parameter occurrence: The domain GoalOccurrence model
    public init(from occurrence: GoalOccurrence) {
        self.id = occurrence.id
        self.userId = occurrence.userId
        self.goalId = occurrence.goalId
        self.scheduleId = nil // Will be set by database
        self.scheduledDate = occurrence.scheduledDate
        self.dueAt = occurrence.dueAt
        self.targetCount = occurrence.targetCount
        self.completedCount = occurrence.completedCount
        self.status = occurrence.status.rawValue
        self.keepUntilComplete = occurrence.keepUntilComplete
        self.rolledFromId = occurrence.rolledFromId
        self.rolledIntoId = occurrence.rolledIntoId
        self.nameOverride = occurrence.nameOverride
        self.emojiOverride = occurrence.emojiOverride
        self.contentSnapshot = occurrence.contentSnapshot.map { ContentSnapshotDTO(from: $0) }
        self.isOneTime = occurrence.isOneTime
        self.createdAt = occurrence.createdAt
        self.updatedAt = occurrence.updatedAt
    }

    /// MARK: - Conversion

    /// Converts the DTO to a domain model
    public var toDomain: GoalOccurrence {
        GoalOccurrence(
            id: id,
            goalId: goalId,
            userId: userId,
            scheduledDate: scheduledDate,
            dueAt: dueAt,
            status: OccurrenceStatus(rawValue: status) ?? .pending,
            targetCount: targetCount,
            completedCount: completedCount,
            keepUntilComplete: keepUntilComplete,
            rolledFromId: rolledFromId,
            rolledIntoId: rolledIntoId,
            nameOverride: nameOverride,
            emojiOverride: emojiOverride,
            contentSnapshot: contentSnapshot?.toDomain,
            isOneTime: isOneTime,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// MARK: - ContentSnapshotDTO

/// Data Transfer Object for ContentSnapshot
///
/// Captures the state of a goal at the time an occurrence was created.
public struct ContentSnapshotDTO: Codable, Sendable, Equatable {
    public let title: String
    public let emoji: String?
    public let points: Int

    enum CodingKeys: String, CodingKey {
        case title
        case emoji
        case points
    }

    public init(from snapshot: ContentSnapshot) {
        self.title = snapshot.title
        self.emoji = snapshot.emoji
        self.points = snapshot.points
    }

    public var toDomain: ContentSnapshot {
        ContentSnapshot(
            title: title,
            emoji: emoji,
            points: points
        )
    }
}
