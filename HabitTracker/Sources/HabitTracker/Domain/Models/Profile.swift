import Foundation

/// User profile with preferences and statistics
///
/// Extends the Supabase auth.users table with app-specific data.
@Observable
public final class Profile: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var displayName: String?
    public var avatarURL: String?
    public var timezone: String
    public var weekStartsOn: Int
    public var dailyReminderEnabled: Bool
    public var dailyReminderTime: Date?
    public var totalPoints: Int
    public var currentStreak: Int
    public var longestStreak: Int
    public let createdAt: Date
    public var updatedAt: Date

    // MARK: - Initialization

    public init(
        id: UUID,
        displayName: String? = nil,
        avatarURL: String? = nil,
        timezone: String = TimeZone.current.identifier,
        weekStartsOn: Int = 1, // 1 = Monday (ISO 8601)
        dailyReminderEnabled: Bool = false,
        dailyReminderTime: Date? = nil,
        totalPoints: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
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
    }

    // MARK: - Computed Properties

    /// The user's TimeZone
    public var timeZone: TimeZone {
        TimeZone(identifier: timezone) ?? .current
    }

    /// Display name or "User"
    public var displayNameOrDefault: String {
        displayName ?? "User"
    }

    /// Formatted reminder time
    public var formattedReminderTime: String? {
        guard let time = dailyReminderTime else { return nil }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        return formatter.string(from: time)
    }

    /// Week start day name
    public var weekStartDayName: String {
        switch weekStartsOn {
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        case 6: return "Saturday"
        case 7: return "Sunday"
        default: return "Monday"
        }
    }

    // MARK: - Equatable

    public static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id &&
        lhs.displayName == rhs.displayName &&
        lhs.totalPoints == rhs.totalPoints
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
