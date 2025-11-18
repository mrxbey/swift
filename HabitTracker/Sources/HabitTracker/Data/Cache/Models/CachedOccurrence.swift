import Foundation
import SwiftData

/// SwiftData model for caching GoalOccurrence entities locally
@Model
public final class CachedOccurrence {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var goalId: UUID
    public var scheduledDate: Date
    public var dueAt: Date?
    public var status: String
    public var targetCount: Int
    public var completedCount: Int
    public var keepUntilComplete: Bool
    public var rolledFromId: UUID?
    public var rolledIntoId: UUID?
    public var nameOverride: String?
    public var emojiOverride: String?
    public var contentSnapshotTitle: String?
    public var contentSnapshotEmoji: String?
    public var contentSnapshotPoints: Int
    public var isOneTime: Bool
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
        goalId: UUID,
        scheduledDate: Date,
        dueAt: Date? = nil,
        status: String,
        targetCount: Int,
        completedCount: Int,
        keepUntilComplete: Bool = false,
        rolledFromId: UUID? = nil,
        rolledIntoId: UUID? = nil,
        nameOverride: String? = nil,
        emojiOverride: String? = nil,
        contentSnapshotTitle: String? = nil,
        contentSnapshotEmoji: String? = nil,
        contentSnapshotPoints: Int = 5,
        isOneTime: Bool = false,
        createdAt: Date,
        updatedAt: Date,
        lastSyncedAt: Date? = nil,
        syncState: String = "synced",
        pendingOperation: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.goalId = goalId
        self.scheduledDate = scheduledDate
        self.dueAt = dueAt
        self.status = status
        self.targetCount = targetCount
        self.completedCount = completedCount
        self.keepUntilComplete = keepUntilComplete
        self.rolledFromId = rolledFromId
        self.rolledIntoId = rolledIntoId
        self.nameOverride = nameOverride
        self.emojiOverride = emojiOverride
        self.contentSnapshotTitle = contentSnapshotTitle
        self.contentSnapshotEmoji = contentSnapshotEmoji
        self.contentSnapshotPoints = contentSnapshotPoints
        self.isOneTime = isOneTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.syncState = syncState
        self.pendingOperation = pendingOperation
    }

    /// MARK: - Conversion

    public convenience init(from occurrence: GoalOccurrence, syncState: SyncState = .synced) {
        self.init(
            id: occurrence.id,
            userId: occurrence.userId,
            goalId: occurrence.goalId,
            scheduledDate: occurrence.scheduledDate,
            dueAt: occurrence.dueAt,
            status: occurrence.status.rawValue,
            targetCount: occurrence.targetCount,
            completedCount: occurrence.completedCount,
            keepUntilComplete: occurrence.keepUntilComplete,
            rolledFromId: occurrence.rolledFromId,
            rolledIntoId: occurrence.rolledIntoId,
            nameOverride: occurrence.nameOverride,
            emojiOverride: occurrence.emojiOverride,
            contentSnapshotTitle: occurrence.contentSnapshot?.title,
            contentSnapshotEmoji: occurrence.contentSnapshot?.emoji,
            contentSnapshotPoints: occurrence.contentSnapshot?.points ?? 5,
            isOneTime: occurrence.isOneTime,
            createdAt: occurrence.createdAt,
            updatedAt: occurrence.updatedAt,
            lastSyncedAt: syncState == .synced ? Date() : nil,
            syncState: syncState.rawValue,
            pendingOperation: nil
        )
    }

    public func toDomain() -> GoalOccurrence {
        let contentSnapshot: ContentSnapshot? = if let title = contentSnapshotTitle {
            ContentSnapshot(
                title: title,
                emoji: contentSnapshotEmoji,
                points: contentSnapshotPoints
            )
        } else {
            nil
        }

        return GoalOccurrence(
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
            contentSnapshot: contentSnapshot,
            isOneTime: isOneTime,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func update(from occurrence: GoalOccurrence, syncState: SyncState = .pending) {
        self.goalId = occurrence.goalId
        self.scheduledDate = occurrence.scheduledDate
        self.dueAt = occurrence.dueAt
        self.status = occurrence.status.rawValue
        self.targetCount = occurrence.targetCount
        self.completedCount = occurrence.completedCount
        self.keepUntilComplete = occurrence.keepUntilComplete
        self.rolledFromId = occurrence.rolledFromId
        self.rolledIntoId = occurrence.rolledIntoId
        self.nameOverride = occurrence.nameOverride
        self.emojiOverride = occurrence.emojiOverride
        self.contentSnapshotTitle = occurrence.contentSnapshot?.title
        self.contentSnapshotEmoji = occurrence.contentSnapshot?.emoji
        self.contentSnapshotPoints = occurrence.contentSnapshot?.points ?? 5
        self.isOneTime = occurrence.isOneTime
        self.updatedAt = occurrence.updatedAt
        self.syncState = syncState.rawValue
        if syncState == .synced {
            self.lastSyncedAt = Date()
        }
    }
}
