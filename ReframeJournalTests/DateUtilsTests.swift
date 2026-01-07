import XCTest
@testable import ReframeJournal

final class DateUtilsTests: XCTestCase {
    
    // MARK: - nowIso Tests
    
    func testNowIsoReturnsValidISO8601String() {
        let iso = DateUtils.nowIso()
        
        // Should be parseable
        let parsed = DateUtils.parseIso(iso)
        XCTAssertNotNil(parsed)
        
        // Should be recent (within last minute)
        if let parsed = parsed {
            let diff = Date().timeIntervalSince(parsed)
            XCTAssertLessThan(diff, 60)
        }
    }
    
    // MARK: - isoString Tests
    
    func testIsoStringFromDate() {
        let date = Date(timeIntervalSince1970: 1700000000)
        let iso = DateUtils.isoString(from: date)
        
        XCTAssertTrue(iso.contains("2023"))
        XCTAssertTrue(iso.contains("T"))
    }
    
    func testIsoStringRoundTrip() {
        let original = Date(timeIntervalSince1970: 1705312800) // Fixed timestamp
        let iso = DateUtils.isoString(from: original)
        let parsed = DateUtils.parseIso(iso)
        
        XCTAssertNotNil(parsed)
        // Allow small precision difference due to fractional seconds
        if let parsed = parsed {
            XCTAssertEqual(original.timeIntervalSince1970, parsed.timeIntervalSince1970, accuracy: 0.001)
        }
    }
    
    // MARK: - parseIso Tests
    
    func testParseIsoWithFractionalSeconds() {
        let iso = "2024-01-15T10:30:00.123Z"
        let parsed = DateUtils.parseIso(iso)
        
        XCTAssertNotNil(parsed)
    }
    
    func testParseIsoWithoutFractionalSeconds() {
        let iso = "2024-01-15T10:30:00Z"
        let parsed = DateUtils.parseIso(iso)
        
        XCTAssertNotNil(parsed)
    }
    
    func testParseIsoWithInvalidString() {
        let invalid = "not-a-date"
        let parsed = DateUtils.parseIso(invalid)
        
        XCTAssertNil(parsed)
    }
    
    func testParseIsoWithEmptyString() {
        let empty = ""
        let parsed = DateUtils.parseIso(empty)
        
        XCTAssertNil(parsed)
    }
    
    // MARK: - formatRelativeDate Tests
    
    func testFormatRelativeDateToday() {
        let now = Date()
        let iso = DateUtils.isoString(from: now)
        let result = DateUtils.formatRelativeDate(iso)
        
        XCTAssertEqual(result, "Today")
    }
    
    func testFormatRelativeDateYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        // Make sure it's clearly yesterday (middle of the day)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: yesterday)
        var noonComponents = components
        noonComponents.hour = 12
        let yesterdayNoon = Calendar.current.date(from: noonComponents)!
        
        let iso = DateUtils.isoString(from: yesterdayNoon)
        let result = DateUtils.formatRelativeDate(iso)
        
        XCTAssertEqual(result, "Yesterday")
    }
    
    func testFormatRelativeDateOlder() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let iso = DateUtils.isoString(from: oldDate)
        let result = DateUtils.formatRelativeDate(iso)
        
        // Should not be "Today" or "Yesterday"
        XCTAssertNotEqual(result, "Today")
        XCTAssertNotEqual(result, "Yesterday")
        // Should contain date-like content (numbers)
        XCTAssertTrue(result.contains(where: { $0.isNumber }))
    }
    
    func testFormatRelativeDateInvalidReturnsOriginal() {
        let invalid = "invalid-date"
        let result = DateUtils.formatRelativeDate(invalid)
        
        XCTAssertEqual(result, invalid)
    }
    
    // MARK: - formatRelativeDateTime Tests
    
    func testFormatRelativeDateTimeToday() {
        let now = Date()
        let iso = DateUtils.isoString(from: now)
        let result = DateUtils.formatRelativeDateTime(iso)
        
        XCTAssertTrue(result.hasPrefix("Today"))
        XCTAssertTrue(result.contains("·"))
    }
    
    func testFormatRelativeDateTimeYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let components = Calendar.current.dateComponents([.year, .month, .day], from: yesterday)
        var noonComponents = components
        noonComponents.hour = 12
        let yesterdayNoon = Calendar.current.date(from: noonComponents)!
        
        let iso = DateUtils.isoString(from: yesterdayNoon)
        let result = DateUtils.formatRelativeDateTime(iso)
        
        XCTAssertTrue(result.hasPrefix("Yesterday"))
        XCTAssertTrue(result.contains("·"))
    }
    
    func testFormatRelativeDateTimeInvalidReturnsOriginal() {
        let invalid = "invalid-date"
        let result = DateUtils.formatRelativeDateTime(invalid)
        
        XCTAssertEqual(result, invalid)
    }
}
