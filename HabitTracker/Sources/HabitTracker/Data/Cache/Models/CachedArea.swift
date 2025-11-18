import Foundation
import SwiftData

/// SwiftData model for caching Area entities locally
///
/// Mirrors the Area domain model but adds sync metadata for offline-first functionality.
@Model
public final class CachedArea {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var name: String
    public var emoji: String?
    public var colorHex: String?
    public var status: String
    public var createdAt: Date
    public var updatedAt: Date

    // Sync metadata
    public var lastSyncedAt: Date?
    public var syncState: String // "synced", "pending", "failed"
    public var pendingOperation: String? // "create", "update", "delete"

    // MARK: - Initialization

    public init(
        id: UUID,
        userId: UUID,
        name: String,
        emoji: String? = nil,
        colorHex: String? = nil,
        status: String,
        createdAt: Date,
        updatedAt: Date,
        lastSyncedAt: Date? = nil,
        syncState: String = "synced",
        pendingOperation: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.syncState = syncState
        self.pendingOperation = pendingOperation
    }

    // MARK: - Conversion

    /// Creates a cached model from a domain model
    public convenience init(from area: Area, syncState: SyncState = .synced) {
        self.init(
            id: area.id,
            userId: area.userId,
            name: area.name,
            emoji: area.emoji,
            colorHex: area.colorHex,
            status: area.status.rawValue,
            createdAt: area.createdAt,
            updatedAt: area.updatedAt,
            lastSyncedAt: syncState == .synced ? Date() : nil,
            syncState: syncState.rawValue,
            pendingOperation: nil
        )
    }

    /// Converts to domain model
    public func toDomain() -> Area {
        Area(
            id: id,
            userId: userId,
            name: name,
            emoji: emoji,
            colorHex: colorHex,
            status: AreaStatus(rawValue: status) ?? .active,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Updates from domain model
    public func update(from area: Area, syncState: SyncState = .pending) {
        self.name = area.name
        self.emoji = area.emoji
        self.colorHex = area.colorHex
        self.status = area.status.rawValue
        self.updatedAt = area.updatedAt
        self.syncState = syncState.rawValue
        if syncState == .synced {
            self.lastSyncedAt = Date()
        }
    }
}

// MARK: - SyncState

public enum SyncState: String, Codable {
    case synced = "synced"
    case pending = "pending"
    case failed = "failed"
}

// MARK: - PendingOperation

public enum PendingOperation: String, Codable {
    case create = "create"
    case update = "update"
    case delete = "delete"
}
