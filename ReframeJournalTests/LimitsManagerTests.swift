// File: Tests/LimitsManagerTests.swift
import XCTest
@testable import ReframeJournal

final class LimitsManagerTests: XCTestCase {
    func testDailyResetResetsCounts() {
        let suiteName = "limits.tests.daily.reset"
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

    func testRollingWindowEnforcement() {
        let suiteName = "limits.tests.rolling.window"
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
}
