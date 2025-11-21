import Foundation
import SwiftData

/// SwiftData model for caching Reflection entities locally
///
/// Mirrors the Reflection domain model but adds sync metadata for offline-first functionality.
@Model
public final class CachedReflection {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var goalId: UUID?
    public var areaId: UUID?
    public var content: String
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData"))
    public var tags: [String]
    public var mood: String?
    public var reflectionDate: Date
    public var createdAt: Date
    public var updatedAt: Date

    // Sync metadata
    public var lastSyncedAt: Date?
    public var syncState: String // "synced", "pending", "failed"
    public var pendingOperation: String? // "create", "update", "delete"

    /// MARK: - Initialization

    public init(
        id: UUID,
        userId: UUID,
        goalId: UUID? = nil,
        areaId: UUID? = nil,
        content: String,
        tags: [String],
        mood: String? = nil,
        reflectionDate: Date,
        createdAt: Date,
        updatedAt: Date,
        lastSyncedAt: Date? = nil,
        syncState: String = "synced",
        pendingOperation: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.goalId = goalId
        self.areaId = areaId
        self.content = content
        self.tags = tags
        self.mood = mood
        self.reflectionDate = reflectionDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.syncState = syncState
        self.pendingOperation = pendingOperation
    }

    /// MARK: - Conversion

    /// Creates a cached model from a domain model
    public convenience init(from reflection: Reflection, syncState: SyncState = .synced) {
        self.init(
            id: reflection.id,
            userId: reflection.userId,
            goalId: reflection.goalId,
            areaId: reflection.areaId,
            content: reflection.content,
            tags: reflection.tags,
            mood: reflection.mood?.rawValue,
            reflectionDate: reflection.reflectionDate,
            createdAt: reflection.createdAt,
            updatedAt: reflection.updatedAt,
            lastSyncedAt: syncState == .synced ? Date() : nil,
            syncState: syncState.rawValue,
            pendingOperation: nil
        )
    }

    /// Converts to domain model
    public func toDomain() -> Reflection {
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

    /// Updates from domain model
    public func update(from reflection: Reflection, syncState: SyncState = .pending) {
        self.goalId = reflection.goalId
        self.areaId = reflection.areaId
        self.content = reflection.content
        self.tags = reflection.tags
        self.mood = reflection.mood?.rawValue
        self.reflectionDate = reflection.reflectionDate
        self.updatedAt = reflection.updatedAt
        self.syncState = syncState.rawValue
        if syncState == .synced {
            self.lastSyncedAt = Date()
        }
    }
}
