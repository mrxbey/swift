import Foundation
import SwiftData

/// SwiftData model for caching Measurement entities locally
@Model
public final class CachedMeasurement {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var goalId: UUID
    public var occurrenceId: UUID?
    public var value: Double
    public var unit: String
    public var recordedAt: Date
    public var createdAt: Date

    // Sync metadata
    public var lastSyncedAt: Date?
    public var syncState: String
    public var pendingOperation: String?

    /// MARK: - Initialization

    public init(
        id: UUID,
        userId: UUID,
        goalId: UUID,
        occurrenceId: UUID? = nil,
        value: Double,
        unit: String,
        recordedAt: Date,
        createdAt: Date,
        lastSyncedAt: Date? = nil,
        syncState: String = "synced",
        pendingOperation: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.goalId = goalId
        self.occurrenceId = occurrenceId
        self.value = value
        self.unit = unit
        self.recordedAt = recordedAt
        self.createdAt = createdAt
        self.lastSyncedAt = lastSyncedAt
        self.syncState = syncState
        self.pendingOperation = pendingOperation
    }

    /// MARK: - Conversion

    public convenience init(from measurement: Measurement, syncState: SyncState = .synced) {
        self.init(
            id: measurement.id,
            userId: measurement.userId,
            goalId: measurement.goalId,
            occurrenceId: measurement.occurrenceId,
            value: measurement.value,
            unit: measurement.unit.rawValue,
            recordedAt: measurement.recordedAt,
            createdAt: measurement.createdAt,
            lastSyncedAt: syncState == .synced ? Date() : nil,
            syncState: syncState.rawValue,
            pendingOperation: nil
        )
    }

    public func toDomain() -> Measurement {
        Measurement(
            id: id,
            userId: userId,
            goalId: goalId,
            occurrenceId: occurrenceId,
            value: value,
            unit: UnitKind(rawValue: unit) ?? .count,
            recordedAt: recordedAt,
            createdAt: createdAt
        )
    }

    public func update(from measurement: Measurement, syncState: SyncState = .pending) {
        self.goalId = measurement.goalId
        self.occurrenceId = measurement.occurrenceId
        self.value = measurement.value
        self.unit = measurement.unit.rawValue
        self.recordedAt = measurement.recordedAt
        self.syncState = syncState.rawValue
        if syncState == .synced {
            self.lastSyncedAt = Date()
        }
    }
}
