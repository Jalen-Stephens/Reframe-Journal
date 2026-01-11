// File: Tests/LimitsManagerTests.swift
import XCTest
@testable import ReframeJournal

final class LimitsManagerTests: XCTestCase {
    
    @MainActor
    private func createManager(suiteName: String, nowProvider: @escaping () -> Date) -> (LimitsManager, UserDefaults, Calendar) {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let manager = LimitsManager(storage: defaults, calendar: calendar, nowProvider: nowProvider)
        return (manager, defaults, calendar)
    }
    
    // MARK: - Initial State Tests
    
    @MainActor
    func testInitialStateHasZeroCounts() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.initial.\(UUID().uuidString)") { now }
        
        XCTAssertEqual(manager.dailyThoughtCount, 0)
        XCTAssertEqual(manager.dailyReframeCount, 0)
        XCTAssertEqual(manager.recentReframeCount, 0)
    }
    
    // MARK: - Thought Recording Tests
    
    @MainActor
    func testRecordThoughtIncrementsCount() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.record.thought.\(UUID().uuidString)") { now }
        
        manager.recordThought()
        
        XCTAssertEqual(manager.dailyThoughtCount, 1)
    }
    
    @MainActor
    func testRecordMultipleThoughts() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.multiple.thoughts.\(UUID().uuidString)") { now }
        
        manager.recordThought()
        manager.recordThought()
        manager.recordThought()
        
        XCTAssertEqual(manager.dailyThoughtCount, 3)
    }
    
    // MARK: - Reframe Recording Tests
    
    @MainActor
    func testRecordReframeIncrementsCount() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.record.reframe.\(UUID().uuidString)") { now }
        
        manager.recordReframe()
        
        XCTAssertEqual(manager.dailyReframeCount, 1)
        XCTAssertEqual(manager.recentReframeCount, 1)
    }
    
    @MainActor
    func testRecordMultipleReframes() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.multiple.reframes.\(UUID().uuidString)") { now }
        
        manager.recordReframe()
        manager.recordReframe()
        manager.recordReframe()
        
        XCTAssertEqual(manager.dailyReframeCount, 3)
        XCTAssertEqual(manager.recentReframeCount, 3)
    }
    
    // MARK: - Daily Reset Tests
    
    @MainActor
    func testDailyResetResetsCounts() async {
        let suiteName = "limits.tests.daily.reset.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var now = Date(timeIntervalSince1970: 1_700_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let manager = LimitsManager(storage: defaults, calendar: calendar, nowProvider: { now })
        manager.recordThought()
        manager.recordReframe()

        now = calendar.date(byAdding: .day, value: 1, to: now)!
        manager.refreshIfNeeded()

        XCTAssertEqual(manager.dailyThoughtCount, 0)
        XCTAssertEqual(manager.dailyReframeCount, 0)
    }
    
    @MainActor
    func testNoResetOnSameDay() async {
        var now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.same.day.\(UUID().uuidString)") { now }
        
        manager.recordThought()
        manager.recordReframe()
        
        // Move forward 1 hour, same day
        now = now.addingTimeInterval(3600)
        manager.refreshIfNeeded()
        
        XCTAssertEqual(manager.dailyThoughtCount, 1)
        XCTAssertEqual(manager.dailyReframeCount, 1)
    }
    
    // MARK: - assertCanCreateThought Tests
    
    @MainActor
    func testAssertCanCreateThoughtProUserNoLimit() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.pro.user.\(UUID().uuidString)") { now }
        
        // Record 10 thoughts (way over free limit)
        for _ in 0..<10 {
            manager.recordThought()
        }
        
        // Pro user should still be able to create
        XCTAssertNoThrow(try manager.assertCanCreateThought(isPro: true))
    }
    
    @MainActor
    func testAssertCanCreateThoughtFreeUserWithinLimit() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.free.within.\(UUID().uuidString)") { now }
        
        // Free users get 3 thoughts/day
        manager.recordThought()
        manager.recordThought()
        
        XCTAssertNoThrow(try manager.assertCanCreateThought(isPro: false))
    }
    
    @MainActor
    func testAssertCanCreateThoughtFreeUserAtLimit() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.free.at.limit.\(UUID().uuidString)") { now }
        
        // Free users get 3 thoughts/day
        manager.recordThought()
        manager.recordThought()
        manager.recordThought()
        
        XCTAssertThrowsError(try manager.assertCanCreateThought(isPro: false)) { error in
            XCTAssertEqual(error as? LimitsManager.LimitError, .dailyThoughtLimitReached)
        }
    }
    
    // MARK: - assertCanGenerateReframe Tests
    
    @MainActor
    func testAssertCanGenerateReframeInitially() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.reframe.initial.\(UUID().uuidString)") { now }
        
        XCTAssertNoThrow(try manager.assertCanGenerateReframe())
    }

    @MainActor
    func testRollingWindowEnforcement() async {
        let suiteName = "limits.tests.rolling.window.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var now = Date(timeIntervalSince1970: 1_700_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let manager = LimitsManager(storage: defaults, calendar: calendar, nowProvider: { now })

        for _ in 0..<5 {
            manager.recordReframe()
        }

        XCTAssertThrowsError(try manager.assertCanGenerateReframe())

        now = now.addingTimeInterval(11 * 60)
        manager.refreshIfNeeded()
        XCTAssertNoThrow(try manager.assertCanGenerateReframe())
    }
    
    @MainActor
    func testRollingWindowPartialExpiry() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.partial.expiry.\(UUID().uuidString)") { now }
        
        // Record 3 reframes
        manager.recordReframe()
        manager.recordReframe()
        manager.recordReframe()
        
        XCTAssertNoThrow(try manager.assertCanGenerateReframe())
        
        // Record 2 more (now at limit)
        manager.recordReframe()
        manager.recordReframe()
        
        XCTAssertThrowsError(try manager.assertCanGenerateReframe())
    }
    
    // MARK: - LimitError Tests
    
    @MainActor
    func testLimitErrorDescriptions() async {
        XCTAssertNotNil(LimitsManager.LimitError.dailyThoughtLimitReached.errorDescription)
        XCTAssertNotNil(LimitsManager.LimitError.dailyReframeLimitReached.errorDescription)
        XCTAssertNotNil(LimitsManager.LimitError.rollingWindowLimitReached.errorDescription)
        
        XCTAssertTrue(LimitsManager.LimitError.dailyThoughtLimitReached.errorDescription!.contains("entry"))
        XCTAssertTrue(LimitsManager.LimitError.dailyReframeLimitReached.errorDescription!.contains("AI"))
        XCTAssertTrue(LimitsManager.LimitError.rollingWindowLimitReached.errorDescription!.contains("AI"))
    }
    
    // MARK: - Persistence Tests
    
    @MainActor
    func testCountsPersistAcrossInstances() async {
        let suiteName = "limits.tests.persistence.\(UUID().uuidString)"
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        
        // Create first instance and record
        let defaults1 = UserDefaults(suiteName: suiteName)!
        defaults1.removePersistentDomain(forName: suiteName)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let manager1 = LimitsManager(storage: defaults1, calendar: calendar, nowProvider: { now })
        manager1.recordThought()
        manager1.recordThought()
        manager1.recordReframe()
        
        // Create second instance with same storage
        let defaults2 = UserDefaults(suiteName: suiteName)!
        let manager2 = LimitsManager(storage: defaults2, calendar: calendar, nowProvider: { now })
        
        XCTAssertEqual(manager2.dailyThoughtCount, 2)
        XCTAssertEqual(manager2.dailyReframeCount, 1)
    }
    
    // MARK: - Edge Case Tests
    
    @MainActor
    func testRefreshWithClockMovedBackward() async {
        let suiteName = "limits.tests.clock.backward.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        
        var now = Date(timeIntervalSince1970: 1_700_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let manager = LimitsManager(storage: defaults, calendar: calendar, nowProvider: { now })
        manager.recordThought()
        
        // Move clock backward (e.g., timezone change or manual adjustment)
        now = now.addingTimeInterval(-3600 * 24) // 1 day back
        manager.refreshIfNeeded()
        
        // Should reset because lastReset > now
        XCTAssertEqual(manager.dailyThoughtCount, 0)
    }
    
    @MainActor
    func testDailyReframeLimitEnforcement() async {
        var now = Date(timeIntervalSince1970: 1_700_000_000)
        let (manager, _, _) = createManager(suiteName: "limits.tests.daily.reframe.limit.\(UUID().uuidString)") { now }
        
        // Record 30 reframes (daily limit), spreading them over time to avoid rolling window
        for _ in 0..<30 {
            manager.recordReframe()
            now = now.addingTimeInterval(61) // Move 1 minute between each to clear rolling window
            manager.refreshIfNeeded()
        }
        
        // Should hit daily limit
        XCTAssertThrowsError(try manager.assertCanGenerateReframe()) { error in
            XCTAssertEqual(error as? LimitsManager.LimitError, .dailyReframeLimitReached)
        }
    }
}
