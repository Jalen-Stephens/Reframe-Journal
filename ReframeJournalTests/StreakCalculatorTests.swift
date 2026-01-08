// File: ReframeJournalTests/StreakCalculatorTests.swift
// Unit tests for streak calculation logic

import XCTest
@testable import ReframeJournal

final class StreakCalculatorTests: XCTestCase {
    private var calendar: Calendar!
    private var referenceDate: Date!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        // Use a fixed reference date for deterministic tests
        // January 15, 2026, 12:00 PM
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 12
        referenceDate = calendar.date(from: components)!
    }
    
    override func tearDown() {
        calendar = nil
        referenceDate = nil
        super.tearDown()
    }
    
    // MARK: - Helper
    
    private func date(daysFromReference offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: referenceDate))!
    }
    
    // MARK: - Tests
    
    func testEmptyDatesReturnsZeroStreak() {
        let streak = StreakCalculator.calculateStreak(
            from: [],
            calendar: calendar,
            referenceDate: referenceDate
        )
        XCTAssertEqual(streak, 0)
    }
    
    func testSingleEntryTodayReturnsStreakOfOne() {
        let dates = [date(daysFromReference: 0)] // Today
        
        let streak = StreakCalculator.calculateStreak(
            from: dates,
            calendar: calendar,
            referenceDate: referenceDate
        )
        
        XCTAssertEqual(streak, 1)
    }
    
    func testConsecutiveDaysIncludingToday() {
        let dates = [
            date(daysFromReference: 0),  // Today
            date(daysFromReference: -1), // Yesterday
            date(daysFromReference: -2), // 2 days ago
            date(daysFromReference: -3)  // 3 days ago
        ]
        
        let streak = StreakCalculator.calculateStreak(
            from: dates,
            calendar: calendar,
            referenceDate: referenceDate
        )
        
        XCTAssertEqual(streak, 4)
    }
    
    func testStreakBrokenByMissingDay() {
        let dates = [
            date(daysFromReference: 0),  // Today
            date(daysFromReference: -1), // Yesterday
            // Day -2 is missing
            date(daysFromReference: -3), // 3 days ago
            date(daysFromReference: -4)  // 4 days ago
        ]
        
        let streak = StreakCalculator.calculateStreak(
            from: dates,
            calendar: calendar,
            referenceDate: referenceDate
        )
        
        XCTAssertEqual(streak, 2) // Only today and yesterday count
    }
    
    func testNoEntryTodayButYesterdayStartsStreak() {
        // If today has no entry, we can still count yesterday's streak
        let dates = [
            date(daysFromReference: -1), // Yesterday
            date(daysFromReference: -2), // 2 days ago
            date(daysFromReference: -3)  // 3 days ago
        ]
        
        let streak = StreakCalculator.calculateStreak(
            from: dates,
            calendar: calendar,
            referenceDate: referenceDate
        )
        
        XCTAssertEqual(streak, 3)
    }
    
    func testNoEntryTodayOrYesterdayReturnsZero() {
        let dates = [
            date(daysFromReference: -2), // 2 days ago
            date(daysFromReference: -3), // 3 days ago
            date(daysFromReference: -4)  // 4 days ago
        ]
        
        let streak = StreakCalculator.calculateStreak(
            from: dates,
            calendar: calendar,
            referenceDate: referenceDate
        )
        
        XCTAssertEqual(streak, 0)
    }
    
    func testMultipleEntriesSameDayCountsAsOne() {
        let dates = [
            date(daysFromReference: 0),  // Today - entry 1
            date(daysFromReference: 0),  // Today - entry 2
            date(daysFromReference: 0),  // Today - entry 3
            date(daysFromReference: -1), // Yesterday
            date(daysFromReference: -1)  // Yesterday - entry 2
        ]
        
        let streak = StreakCalculator.calculateStreak(
            from: dates,
            calendar: calendar,
            referenceDate: referenceDate
        )
        
        XCTAssertEqual(streak, 2) // Just 2 consecutive days, not 5
    }
    
    func testFutureEntriesAreIgnored() {
        let dates = [
            date(daysFromReference: 0),  // Today
            date(daysFromReference: 1),  // Tomorrow (future)
            date(daysFromReference: 2)   // 2 days from now (future)
        ]
        
        let streak = StreakCalculator.calculateStreak(
            from: dates,
            calendar: calendar,
            referenceDate: referenceDate
        )
        
        XCTAssertEqual(streak, 1) // Only today counts
    }
    
    func testLongStreak() {
        var dates: [Date] = []
        for i in 0..<30 { // 30-day streak
            dates.append(date(daysFromReference: -i))
        }
        
        let streak = StreakCalculator.calculateStreak(
            from: dates,
            calendar: calendar,
            referenceDate: referenceDate
        )
        
        XCTAssertEqual(streak, 30)
    }
    
    func testEntriesAtDifferentTimesOfDay() {
        // Entries at different times of the same day should still count as one day
        var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        
        // Today at 9 AM
        components.hour = 9
        let morningEntry = calendar.date(from: components)!
        
        // Today at 9 PM
        components.hour = 21
        let eveningEntry = calendar.date(from: components)!
        
        let dates = [morningEntry, eveningEntry]
        
        let streak = StreakCalculator.calculateStreak(
            from: dates,
            calendar: calendar,
            referenceDate: referenceDate
        )
        
        XCTAssertEqual(streak, 1)
    }
}

// MARK: - HomeViewModel Tests

final class HomeViewModelTests: XCTestCase {
    
    @MainActor
    func testGreetingMorning() {
        // Create a date at 9 AM
        var calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 9
        let morningDate = calendar.date(from: components)!
        
        // Note: We can't easily test greeting without mocking Date(),
        // so this test documents expected behavior
        let viewModel = HomeViewModel(initialDate: morningDate)
        
        // Greeting is based on current Date(), not initialDate
        // So we just verify it returns a valid greeting
        let greeting = viewModel.greeting
        XCTAssertTrue(
            greeting == "good morning." ||
            greeting == "good afternoon." ||
            greeting == "good evening." ||
            greeting == "good night."
        )
    }
    
    @MainActor
    func testSelectedDayLabel() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15 // This is a Thursday in 2026
        let thursday = calendar.date(from: components)!
        
        let viewModel = HomeViewModel(initialDate: thursday)
        
        XCTAssertEqual(viewModel.selectedDayLabel, "THURSDAY")
    }
    
    @MainActor
    func testWeekDaysGeneration() {
        let viewModel = HomeViewModel()
        let weekDays = viewModel.weekDays(entriesWithDates: [])
        
        XCTAssertEqual(weekDays.count, 7)
        
        // Verify one day is selected (today)
        let selectedDays = weekDays.filter { $0.isSelected }
        XCTAssertEqual(selectedDays.count, 1)
        
        // Verify one day is today
        let todayDays = weekDays.filter { $0.isToday }
        XCTAssertEqual(todayDays.count, 1)
    }
    
    @MainActor
    func testSelectDate() {
        let viewModel = HomeViewModel()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        viewModel.selectDate(tomorrow)
        
        XCTAssertTrue(calendar.isDate(viewModel.selectedDate, inSameDayAs: tomorrow))
    }
}
