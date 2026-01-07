import XCTest
@testable import ReframeJournal

final class MetricsTests: XCTestCase {
    
    // MARK: - clampPercent(Int) Tests
    
    func testClampPercentIntNormalValue() {
        XCTAssertEqual(Metrics.clampPercent(50), 50)
        XCTAssertEqual(Metrics.clampPercent(0), 0)
        XCTAssertEqual(Metrics.clampPercent(100), 100)
    }
    
    func testClampPercentIntNegativeValue() {
        XCTAssertEqual(Metrics.clampPercent(-1), 0)
        XCTAssertEqual(Metrics.clampPercent(-100), 0)
        XCTAssertEqual(Metrics.clampPercent(Int.min), 0)
    }
    
    func testClampPercentIntOverValue() {
        XCTAssertEqual(Metrics.clampPercent(101), 100)
        XCTAssertEqual(Metrics.clampPercent(200), 100)
        XCTAssertEqual(Metrics.clampPercent(Int.max), 100)
    }
    
    func testClampPercentIntBoundaryValues() {
        XCTAssertEqual(Metrics.clampPercent(-10), 0)
        XCTAssertEqual(Metrics.clampPercent(120), 100)
    }
    
    // MARK: - clampPercent(Double) Tests
    
    func testClampPercentDoubleNormalValue() {
        XCTAssertEqual(Metrics.clampPercent(50.0), 50)
        XCTAssertEqual(Metrics.clampPercent(0.0), 0)
        XCTAssertEqual(Metrics.clampPercent(100.0), 100)
    }
    
    func testClampPercentDoubleRounding() {
        XCTAssertEqual(Metrics.clampPercent(50.4), 50)
        XCTAssertEqual(Metrics.clampPercent(50.5), 50) // Rounds to nearest even
        XCTAssertEqual(Metrics.clampPercent(50.6), 51)
        XCTAssertEqual(Metrics.clampPercent(49.5), 50) // Rounds to nearest even
    }
    
    func testClampPercentDoubleNegativeValue() {
        XCTAssertEqual(Metrics.clampPercent(-1.5), 0)
        XCTAssertEqual(Metrics.clampPercent(-100.0), 0)
    }
    
    func testClampPercentDoubleOverValue() {
        XCTAssertEqual(Metrics.clampPercent(100.5), 100)
        XCTAssertEqual(Metrics.clampPercent(150.0), 100)
    }
    
    // MARK: - isRequiredTextValid Tests
    
    func testIsRequiredTextValidWithContent() {
        XCTAssertTrue(Metrics.isRequiredTextValid("hello"))
        XCTAssertTrue(Metrics.isRequiredTextValid("a"))
        XCTAssertTrue(Metrics.isRequiredTextValid("hello world"))
        XCTAssertTrue(Metrics.isRequiredTextValid("  hello  "))
    }
    
    func testIsRequiredTextValidWithEmpty() {
        XCTAssertFalse(Metrics.isRequiredTextValid(""))
    }
    
    func testIsRequiredTextValidWithWhitespaceOnly() {
        XCTAssertFalse(Metrics.isRequiredTextValid("   "))
        XCTAssertFalse(Metrics.isRequiredTextValid("\t"))
        XCTAssertFalse(Metrics.isRequiredTextValid("\n"))
        XCTAssertFalse(Metrics.isRequiredTextValid("  \t\n  "))
    }
    
    func testIsRequiredTextValidWithNewlines() {
        XCTAssertTrue(Metrics.isRequiredTextValid("line1\nline2"))
        XCTAssertFalse(Metrics.isRequiredTextValid("\n\n\n"))
    }
}
