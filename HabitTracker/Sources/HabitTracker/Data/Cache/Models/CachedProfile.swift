import Foundation
import SwiftData

/// SwiftData model for caching Profile entities locally
///
/// Mirrors the Profile domain model but adds sync metadata for offline-first functionality.
@Model
public final class CachedProfile {
    @Attribute(.unique) public var id: UUID
    public var displayName: String?
    public var avatarURL: String?
    public var timezone: String
    public var weekStartsOn: Int
    public var dailyReminderEnabled: Bool
    public var dailyReminderTime: Date?
    public var totalPoints: Int
    public var currentStreak: Int
    public var longestStreak: Int
    public var createdAt: Date
    public var updatedAt: Date

    // Sync metadata
    public var lastSyncedAt: Date?
    public var syncState: String // "synced", "pending", "failed"
    public var pendingOperation: String? // "create", "update", "delete"

    /// MARK: - Initialization

    public init(
        id: UUID,
        displayName: String? = nil,
        avatarURL: String? = nil,
        timezone: String,
        weekStartsOn: Int,
        dailyReminderEnabled: Bool,
        dailyReminderTime: Date? = nil,
        totalPoints: Int,
        currentStreak: Int,
        longestStreak: Int,
        createdAt: Date,
        updatedAt: Date,
        lastSyncedAt: Date? = nil,
        syncState: String = "synced",
        pendingOperation: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.timezone = timezone
        self.weekStartsOn = weekStartsOn
        self.dailyReminderEnabled = dailyReminderEnabled
        self.dailyReminderTime = dailyReminderTime
        self.totalPoints = totalPoints
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.syncState = syncState
        self.pendingOperation = pendingOperation
    }

    /// MARK: - Conversion

    /// Creates a cached model from a domain model
    public convenience init(from profile: Profile, syncState: SyncState = .synced) {
        self.init(
            id: profile.id,
            displayName: profile.displayName,
            avatarURL: profile.avatarURL,
            timezone: profile.timezone,
            weekStartsOn: profile.weekStartsOn,
            dailyReminderEnabled: profile.dailyReminderEnabled,
            dailyReminderTime: profile.dailyReminderTime,
            totalPoints: profile.totalPoints,
            currentStreak: profile.currentStreak,
            longestStreak: profile.longestStreak,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
            lastSyncedAt: syncState == .synced ? Date() : nil,
            syncState: syncState.rawValue,
            pendingOperation: nil
        )
    }

    /// Converts to domain model
    public func toDomain() -> Profile {
        Profile(
            id: id,
            displayName: displayName,
            avatarURL: avatarURL,
            timezone: timezone,
            weekStartsOn: weekStartsOn,
            dailyReminderEnabled: dailyReminderEnabled,
            dailyReminderTime: dailyReminderTime,
            totalPoints: totalPoints,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Updates from domain model
    public func update(from profile: Profile, syncState: SyncState = .pending) {
        self.displayName = profile.displayName
        self.avatarURL = profile.avatarURL
        self.timezone = profile.timezone
        self.weekStartsOn = profile.weekStartsOn
        self.dailyReminderEnabled = profile.dailyReminderEnabled
        self.dailyReminderTime = profile.dailyReminderTime
        self.totalPoints = profile.totalPoints
        self.currentStreak = profile.currentStreak
        self.longestStreak = profile.longestStreak
        self.updatedAt = profile.updatedAt
        self.syncState = syncState.rawValue
        if syncState == .synced {
            self.lastSyncedAt = Date()
        }
    }
}
