import XCTest
@testable import HabitTracker

final class AreaDTOTests: XCTestCase {

    // MARK: - Domain to DTO Conversion

    func testInitFromDomain() {
        // Given
        let area = TestFixtures.makeArea(
            name: "Health & Fitness",
            emoji: "💪",
            colorHex: "#FF6B6B"
        )

        // When
        let dto = AreaDTO(from: area)

        // Then
        XCTAssertEqual(dto.id, area.id)
        XCTAssertEqual(dto.userId, area.userId)
        XCTAssertEqual(dto.name, "Health & Fitness")
        XCTAssertEqual(dto.emoji, "💪")
        XCTAssertEqual(dto.colorHex, "#FF6B6B")
        XCTAssertEqual(dto.status, "active")
        XCTAssertEqual(dto.createdAt.timeIntervalSince1970, area.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(dto.updatedAt.timeIntervalSince1970, area.updatedAt.timeIntervalSince1970, accuracy: 0.001)
    }

    func testInitFromDomainWithArchivedStatus() {
        // Given
        let area = TestFixtures.makeArea(status: .archived)

        // When
        let dto = AreaDTO(from: area)

        // Then
        XCTAssertEqual(dto.status, "archived")
    }

    // MARK: - DTO to Domain Conversion

    func testToDomain() {
        // Given
        let dto = TestFixtures.makeAreaDTO(
            name: "Productivity",
            emoji: "⚡️",
            colorHex: "#4ECDC4"
        )

        // When
        let area = dto.toDomain

        // Then
        XCTAssertEqual(area.id, dto.id)
        XCTAssertEqual(area.userId, dto.userId)
        XCTAssertEqual(area.name, "Productivity")
        XCTAssertEqual(area.emoji, "⚡️")
        XCTAssertEqual(area.colorHex, "#4ECDC4")
        XCTAssertEqual(area.status, .active)
        XCTAssertEqual(area.createdAt.timeIntervalSince1970, dto.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(area.updatedAt.timeIntervalSince1970, dto.updatedAt.timeIntervalSince1970, accuracy: 0.001)
    }

    func testToDomainWithArchivedStatus() {
        // Given
        let dto = TestFixtures.makeAreaDTO(status: "archived")

        // When
        let area = dto.toDomain

        // Then
        XCTAssertEqual(area.status, .archived)
    }

    // MARK: - Round Trip Conversion

    func testRoundTripConversionPreservesAllFields() {
        // Given
        let originalArea = TestFixtures.makeArea(
            name: "Original Name",
            emoji: "🎯",
            colorHex: "#95E1D3",
            status: .active
        )

        // When
        let dto = AreaDTO(from: originalArea)
        let convertedArea = dto.toDomain

        // Then
        XCTAssertEqual(convertedArea.id, originalArea.id)
        XCTAssertEqual(convertedArea.userId, originalArea.userId)
        XCTAssertEqual(convertedArea.name, originalArea.name)
        XCTAssertEqual(convertedArea.emoji, originalArea.emoji)
        XCTAssertEqual(convertedArea.colorHex, originalArea.colorHex)
        XCTAssertEqual(convertedArea.status, originalArea.status)
        XCTAssertEqual(convertedArea.createdAt.timeIntervalSince1970, originalArea.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(convertedArea.updatedAt.timeIntervalSince1970, originalArea.updatedAt.timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - Codable Tests

    func testCodableEncoding() throws {
        // Given
        let dto = TestFixtures.makeAreaDTO()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        // When
        let data = try encoder.encode(dto)

        // Then
        XCTAssertFalse(data.isEmpty)

        // Verify it can be decoded back
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AreaDTO.self, from: data)
        XCTAssertEqual(decoded.id, dto.id)
        XCTAssertEqual(decoded.name, dto.name)
    }

    func testCodableDecodingFromJSON() throws {
        // Given
        let json = """
        {
            "id": "\(TestFixtures.areaId.uuidString)",
            "user_id": "\(TestFixtures.userId.uuidString)",
            "name": "Test Area",
            "emoji": "✨",
            "color_hex": "#FF0000",
            "status": "active",
            "created_at": "2023-11-14T12:00:00Z",
            "updated_at": "2023-11-14T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // When
        let dto = try decoder.decode(AreaDTO.self, from: json)

        // Then
        XCTAssertEqual(dto.id, TestFixtures.areaId)
        XCTAssertEqual(dto.userId, TestFixtures.userId)
        XCTAssertEqual(dto.name, "Test Area")
        XCTAssertEqual(dto.emoji, "✨")
        XCTAssertEqual(dto.colorHex, "#FF0000")
        XCTAssertEqual(dto.status, "active")
    }

    // MARK: - Edge Cases

    func testEmptyOptionalFields() {
        // Given
        let dto = TestFixtures.makeAreaDTO(
            emoji: nil,
            colorHex: nil
        )

        // When
        let area = dto.toDomain

        // Then
        XCTAssertNil(area.emoji)
        XCTAssertNil(area.colorHex)
    }

    func testSpecialCharactersInName() {
        // Given
        let specialName = "Health & Fitness 🏋️ — 2023"
        let area = TestFixtures.makeArea(name: specialName)

        // When
        let dto = AreaDTO(from: area)
        let convertedArea = dto.toDomain

        // Then
        XCTAssertEqual(convertedArea.name, specialName)
    }
}
