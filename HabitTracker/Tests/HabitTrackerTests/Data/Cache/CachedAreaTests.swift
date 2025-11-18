import XCTest
import SwiftData
@testable import HabitTracker

final class CachedAreaTests: XCTestCase {

    // MARK: - Domain to Cache Conversion

    func testInitFromDomain() {
        // Given
        let area = TestFixtures.makeArea(
            name: "Health",
            emoji: "💪",
            colorHex: "#FF6B6B"
        )

        // When
        let cached = CachedArea(from: area, syncState: .synced)

        // Then
        XCTAssertEqual(cached.id, area.id)
        XCTAssertEqual(cached.userId, area.userId)
        XCTAssertEqual(cached.name, "Health")
        XCTAssertEqual(cached.emoji, "💪")
        XCTAssertEqual(cached.colorHex, "#FF6B6B")
        XCTAssertEqual(cached.status, "active")
        XCTAssertEqual(cached.syncState, "synced")
        XCTAssertNotNil(cached.lastSyncedAt)
    }

    func testInitFromDomainWithPendingState() {
        // Given
        let area = TestFixtures.makeArea()

        // When
        let cached = CachedArea(from: area, syncState: .pending)

        // Then
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertNil(cached.lastSyncedAt)
    }

    // MARK: - Cache to Domain Conversion

    func testToDomain() {
        // Given
        let area = TestFixtures.makeArea(
            name: "Productivity",
            emoji: "⚡️"
        )
        let cached = CachedArea(from: area, syncState: .synced)

        // When
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.id, area.id)
        XCTAssertEqual(converted.userId, area.userId)
        XCTAssertEqual(converted.name, "Productivity")
        XCTAssertEqual(converted.emoji, "⚡️")
        XCTAssertEqual(converted.status, .active)
    }

    // MARK: - Update Method

    func testUpdateFromDomain() {
        // Given
        let originalArea = TestFixtures.makeArea(name: "Original")
        let cached = CachedArea(from: originalArea, syncState: .synced)

        let updatedArea = TestFixtures.makeArea(
            id: originalArea.id,
            name: "Updated",
            emoji: "🎯",
            updatedAt: TestFixtures.laterDate
        )

        // When
        cached.update(from: updatedArea, syncState: .pending)

        // Then
        XCTAssertEqual(cached.name, "Updated")
        XCTAssertEqual(cached.emoji, "🎯")
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertEqual(cached.updatedAt.timeIntervalSince1970, TestFixtures.laterDate.timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - Sync State Management

    func testSyncStateSynced() {
        // Given
        let area = TestFixtures.makeArea()

        // When
        let cached = CachedArea(from: area, syncState: .synced)

        // Then
        XCTAssertEqual(cached.syncState, "synced")
        XCTAssertNotNil(cached.lastSyncedAt)
    }

    func testSyncStatePending() {
        // Given
        let area = TestFixtures.makeArea()

        // When
        let cached = CachedArea(from: area, syncState: .pending)

        // Then
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertNil(cached.lastSyncedAt)
    }

    func testSyncStateFailed() {
        // Given
        let area = TestFixtures.makeArea()

        // When
        let cached = CachedArea(from: area, syncState: .failed)

        // Then
        XCTAssertEqual(cached.syncState, "failed")
        XCTAssertNil(cached.lastSyncedAt)
    }

    // MARK: - Round Trip Conversion

    func testRoundTripConversionPreservesData() {
        // Given
        let originalArea = TestFixtures.makeArea(
            name: "Complete Project",
            emoji: "📝",
            colorHex: "#4ECDC4",
            status: .active
        )

        // When
        let cached = CachedArea(from: originalArea, syncState: .synced)
        let convertedArea = cached.toDomain()

        // Then
        XCTAssertEqual(convertedArea.id, originalArea.id)
        XCTAssertEqual(convertedArea.userId, originalArea.userId)
        XCTAssertEqual(convertedArea.name, originalArea.name)
        XCTAssertEqual(convertedArea.emoji, originalArea.emoji)
        XCTAssertEqual(convertedArea.colorHex, originalArea.colorHex)
        XCTAssertEqual(convertedArea.status, originalArea.status)
    }

    // MARK: - Status Conversion

    func testStatusActiveConversion() {
        // Given
        let area = TestFixtures.makeArea(status: .active)

        // When
        let cached = CachedArea(from: area, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.status, .active)
    }

    func testStatusArchivedConversion() {
        // Given
        let area = TestFixtures.makeArea(status: .archived)

        // When
        let cached = CachedArea(from: area, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.status, .archived)
    }

    // MARK: - Edge Cases

    func testNilOptionalFields() {
        // Given
        let area = TestFixtures.makeArea(emoji: nil, colorHex: nil)

        // When
        let cached = CachedArea(from: area, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertNil(converted.emoji)
        XCTAssertNil(converted.colorHex)
    }

    func testUpdatePreservesSyncMetadata() {
        // Given
        let area = TestFixtures.makeArea()
        let cached = CachedArea(from: area, syncState: .synced)
        let originalSyncDate = cached.lastSyncedAt

        let updatedArea = TestFixtures.makeArea(
            id: area.id,
            name: "Updated"
        )

        // When
        cached.update(from: updatedArea, syncState: .synced)

        // Then
        XCTAssertEqual(cached.name, "Updated")
        XCTAssertNotNil(cached.lastSyncedAt)
        // Sync date should be updated
        if let originalDate = originalSyncDate {
            XCTAssertGreaterThanOrEqual(cached.lastSyncedAt?.timeIntervalSince1970 ?? 0, originalDate.timeIntervalSince1970)
        }
    }
}
