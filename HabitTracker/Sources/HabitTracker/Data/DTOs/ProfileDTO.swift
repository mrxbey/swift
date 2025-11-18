import Foundation

/// Data Transfer Object for Profile entity
///
/// Maps between the PostgreSQL `profiles` table (snake_case) and the Swift `Profile` domain model (camelCase).
public struct ProfileDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let displayName: String?
    public let avatarURL: String?
    public let timezone: String
    public let weekStartsOn: Int
    public let dailyReminderEnabled: Bool
    public let dailyReminderTime: Date?
    public let totalPoints: Int
    public let currentStreak: Int
    public let longestStreak: Int
    public let createdAt: Date
    public let updatedAt: Date

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case timezone
        case weekStartsOn = "week_starts_on"
        case dailyReminderEnabled = "daily_reminder_enabled"
        case dailyReminderTime = "daily_reminder_time"
        case totalPoints = "total_points"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initialization

    /// Creates a DTO from a domain model
    ///
    /// - Parameter profile: The domain Profile model
    public init(from profile: Profile) {
        self.id = profile.id
        self.displayName = profile.displayName
        self.avatarURL = profile.avatarURL
        self.timezone = profile.timezone
        self.weekStartsOn = profile.weekStartsOn
        self.dailyReminderEnabled = profile.dailyReminderEnabled
        self.dailyReminderTime = profile.dailyReminderTime
        self.totalPoints = profile.totalPoints
        self.currentStreak = profile.currentStreak
        self.longestStreak = profile.longestStreak
        self.createdAt = profile.createdAt
        self.updatedAt = profile.updatedAt
    }

    // MARK: - Conversion

    /// Converts the DTO to a domain model
    public var toDomain: Profile {
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
}
