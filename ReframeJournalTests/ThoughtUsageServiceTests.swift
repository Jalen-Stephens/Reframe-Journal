import XCTest
@testable import ReframeJournal

final class ThoughtUsageServiceTests: XCTestCase {
    
    private var service: ThoughtUsageService!
    private var testDefaults: UserDefaults!
    
    override func setUp() async throws {
        try await super.setUp()
        let suiteName = "com.test.thoughtusage.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)
        service = ThoughtUsageService(userDefaults: testDefaults)
    }
    
    override func tearDown() async throws {
        testDefaults = nil
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialCountIsZero() {
        XCTAssertEqual(service.getTodayCount(), 0)
    }
    
    func testInitialCanCreateThought() {
        XCTAssertTrue(service.canCreateThought())
    }
    
    // MARK: - Increment Tests
    
    func testIncrementTodayCount() {
        let didIncrement = service.incrementTodayCount(recordId: "record_1")
        
        XCTAssertTrue(didIncrement)
        XCTAssertEqual(service.getTodayCount(), 1)
    }
    
    func testIncrementMultipleTimes() {
        service.incrementTodayCount(recordId: "record_1")
        service.incrementTodayCount(recordId: "record_2")
        service.incrementTodayCount(recordId: "record_3")
        
        XCTAssertEqual(service.getTodayCount(), 3)
    }
    
    func testIncrementSameRecordIdOnlyCountsOnce() {
        service.incrementTodayCount(recordId: "record_1")
        let second = service.incrementTodayCount(recordId: "record_1")
        
        XCTAssertFalse(second)
        XCTAssertEqual(service.getTodayCount(), 1)
    }
    
    func testIncrementWithDifferentDayCreatedAtDoesNotCount() {
        // Create an ISO string for yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayIso = DateUtils.isoString(from: yesterday)
        
        let didIncrement = service.incrementTodayCount(recordId: "old_record", createdAt: yesterdayIso)
        
        XCTAssertFalse(didIncrement)
        XCTAssertEqual(service.getTodayCount(), 0)
    }
    
    func testIncrementWithTodayCreatedAtCounts() {
        let todayIso = DateUtils.isoString(from: Date())
        
        let didIncrement = service.incrementTodayCount(recordId: "new_record", createdAt: todayIso)
        
        XCTAssertTrue(didIncrement)
        XCTAssertEqual(service.getTodayCount(), 1)
    }
    
    func testIncrementWithNilCreatedAtCounts() {
        let didIncrement = service.incrementTodayCount(recordId: "record", createdAt: nil)
        
        XCTAssertTrue(didIncrement)
        XCTAssertEqual(service.getTodayCount(), 1)
    }
    
    // MARK: - canCreateThought Tests
    
    func testCanCreateThoughtWithZeroCount() {
        XCTAssertTrue(service.canCreateThought())
    }
    
    func testCanCreateThoughtWithOneCount() {
        service.incrementTodayCount(recordId: "r1")
        XCTAssertTrue(service.canCreateThought())
    }
    
    func testCanCreateThoughtWithTwoCount() {
        service.incrementTodayCount(recordId: "r1")
        service.incrementTodayCount(recordId: "r2")
        XCTAssertTrue(service.canCreateThought())
    }
    
    func testCannotCreateThoughtAfterThreeCount() {
        service.incrementTodayCount(recordId: "r1")
        service.incrementTodayCount(recordId: "r2")
        service.incrementTodayCount(recordId: "r3")
        
        XCTAssertFalse(service.canCreateThought())
    }
    
    // MARK: - hasUnlimitedThoughts Tests
    
    func testHasUnlimitedThoughtsIsFalseByDefault() {
        // Currently always returns false (TODO in implementation)
        XCTAssertFalse(service.hasUnlimitedThoughts)
    }
    
    // MARK: - resetIfNewDay Tests
    
    func testResetIfNewDayResetsOnNewDay() {
        // Set usage for "yesterday"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterdayString = formatter.string(from: yesterday)
        
        testDefaults.set(yesterdayString, forKey: "thoughtUsageDate")
        testDefaults.set(5, forKey: "thoughtUsageCount")
        testDefaults.set(["id1", "id2", "id3", "id4", "id5"], forKey: "thoughtUsageIds")
        
        // Create new service which calls resetIfNewDay
        let newService = ThoughtUsageService(userDefaults: testDefaults)
        
        XCTAssertEqual(newService.getTodayCount(), 0)
        XCTAssertTrue(newService.canCreateThought())
    }
    
    func testResetIfNewDayDoesNotResetSameDay() {
        service.incrementTodayCount(recordId: "r1")
        service.incrementTodayCount(recordId: "r2")
        
        service.resetIfNewDay()
        
        XCTAssertEqual(service.getTodayCount(), 2)
    }
}
