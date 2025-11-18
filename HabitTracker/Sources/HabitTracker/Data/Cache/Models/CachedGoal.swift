import Foundation
import SwiftData

/// SwiftData model for caching Goal entities locally
@Model
public final class CachedGoal {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var areaId: UUID
    public var title: String
    public var emoji: String?
    public var kind: String
    public var status: String
    public var keepUntilComplete: Bool
    public var timesPerDay: Int
    public var pointsPerCompletion: Int
    public var linkedExerciseKey: String?
    public var hashtags: [String]
    public var createdAt: Date
    public var updatedAt: Date

    // Sync metadata
    public var lastSyncedAt: Date?
    public var syncState: String
    public var pendingOperation: String?

    /// MARK: - Initialization

    public init(
        id: UUID,
        userId: UUID,
        areaId: UUID,
        title: String,
        emoji: String? = nil,
        kind: String,
        status: String,
        keepUntilComplete: Bool = false,
        timesPerDay: Int = 1,
        pointsPerCompletion: Int = 5,
        linkedExerciseKey: String? = nil,
        hashtags: [String] = [],
        createdAt: Date,
        updatedAt: Date,
        lastSyncedAt: Date? = nil,
        syncState: String = "synced",
        pendingOperation: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.areaId = areaId
        self.title = title
        self.emoji = emoji
        self.kind = kind
        self.status = status
        self.keepUntilComplete = keepUntilComplete
        self.timesPerDay = timesPerDay
        self.pointsPerCompletion = pointsPerCompletion
        self.linkedExerciseKey = linkedExerciseKey
        self.hashtags = hashtags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.syncState = syncState
        self.pendingOperation = pendingOperation
    }

    /// MARK: - Conversion

    public convenience init(from goal: Goal, syncState: SyncState = .synced) {
        self.init(
            id: goal.id,
            userId: goal.userId,
            areaId: goal.areaId,
            title: goal.title,
            emoji: goal.emoji,
            kind: goal.kind.rawValue,
            status: goal.status.rawValue,
            keepUntilComplete: goal.keepUntilComplete,
            timesPerDay: goal.timesPerDay,
            pointsPerCompletion: goal.pointsPerCompletion,
            linkedExerciseKey: goal.linkedExerciseKey?.rawValue,
            hashtags: goal.hashtags,
            createdAt: goal.createdAt,
            updatedAt: goal.updatedAt,
            lastSyncedAt: syncState == .synced ? Date() : nil,
            syncState: syncState.rawValue,
            pendingOperation: nil
        )
    }

    public func toDomain() -> Goal {
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

    public func update(from goal: Goal, syncState: SyncState = .pending) {
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
        self.updatedAt = goal.updatedAt
        self.syncState = syncState.rawValue
        if syncState == .synced {
            self.lastSyncedAt = Date()
        }
    }
}
