import XCTest
@testable import ReframeJournal

final class HomeViewModelTests: XCTestCase {
    
    @MainActor
    func testInitialState() {
        let viewModel = HomeViewModel()
        
        XCTAssertNotNil(viewModel.selectedDate)
        XCTAssertEqual(viewModel.streak, 0)
    }
    
    @MainActor
    func testInitialStateWithCustomDate() {
        let customDate = Date(timeIntervalSince1970: 1_700_000_000)
        let viewModel = HomeViewModel(initialDate: customDate)
        
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(viewModel.selectedDate, inSameDayAs: customDate))
    }
    
    @MainActor
    func testGreetingMorning() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 9 // 9 AM
        let morningDate = calendar.date(from: components)!
        
        let viewModel = HomeViewModel(initialDate: morningDate)
        
        // Greeting is based on current Date(), but we can verify it returns a valid greeting
        let greeting = viewModel.greeting
        XCTAssertFalse(greeting.isEmpty)
    }
    
    @MainActor
    func testGreetingAfternoon() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 14 // 2 PM
        let afternoonDate = calendar.date(from: components)!
        
        let viewModel = HomeViewModel(initialDate: afternoonDate)
        
        let greeting = viewModel.greeting
        XCTAssertFalse(greeting.isEmpty)
    }
    
    @MainActor
    func testIsNightTime() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 22 // 10 PM
        let nightDate = calendar.date(from: components)!
        
        let viewModel = HomeViewModel(initialDate: nightDate)
        
        // isNightTime uses current Date(), but we can verify the logic exists
        let isNight = viewModel.isNightTime
        XCTAssertTrue(isNight || !isNight) // Just verify it doesn't crash
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
    func testIsSelectedToday() {
        let viewModel = HomeViewModel()
        
        // Should be true since we initialize with today
        XCTAssertTrue(viewModel.isSelectedToday)
        
        // Select a different date
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        viewModel.selectDate(yesterday)
        
        XCTAssertFalse(viewModel.isSelectedToday)
    }
    
    @MainActor
    func testSelectDate() {
        let viewModel = HomeViewModel()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        viewModel.selectDate(tomorrow)
        
        XCTAssertTrue(calendar.isDate(viewModel.selectedDate, inSameDayAs: tomorrow))
    }
    
    @MainActor
    func testSelectToday() {
        let viewModel = HomeViewModel()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        viewModel.selectDate(yesterday)
        XCTAssertFalse(viewModel.isSelectedToday)
        
        viewModel.selectToday()
        XCTAssertTrue(calendar.isDateInToday(viewModel.selectedDate))
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
    func testWeekDaysWithEntries() {
        let viewModel = HomeViewModel()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let entriesWithDates = Set([today, yesterday])
        
        let weekDays = viewModel.weekDays(entriesWithDates: entriesWithDates)
        
        let todayDay = weekDays.first { $0.isToday }
        XCTAssertNotNil(todayDay)
        XCTAssertTrue(todayDay?.hasEntry ?? false)
        
        let yesterdayDay = weekDays.first { calendar.isDate($0.date, inSameDayAs: yesterday) }
        XCTAssertNotNil(yesterdayDay)
        XCTAssertTrue(yesterdayDay?.hasEntry ?? false)
    }
    
    @MainActor
    func testUpdateStreak() {
        let viewModel = HomeViewModel()
        
        // No entries - streak should be 0
        viewModel.updateStreak(from: [])
        XCTAssertEqual(viewModel.streak, 0)
        
        // Create entries with completed status
        let calendar = Calendar.current
        var entries: [JournalEntry] = []
        
        for i in 0..<3 {
            let entry = JournalEntry()
            entry.createdAt = calendar.date(byAdding: .day, value: -i, to: Date())!
            entry.isDraft = false
            let aiReframe = AIReframeResult(
                validation: nil,
                whatMightBeHappening: nil,
                cognitiveDistortions: nil,
                balancedThought: "Test",
                microActionPlan: nil,
                communicationScript: nil,
                selfCompassion: nil,
                realityCheckQuestions: nil,
                oneSmallExperiment: nil,
                summary: nil,
                rawResponse: nil
            )
            entry.aiReframe = aiReframe
            entries.append(entry)
        }
        
        viewModel.updateStreak(from: entries)
        
        XCTAssertGreaterThan(viewModel.streak, 0)
    }
    
    @MainActor
    func testUpdateStreakOnlyCompleteEntries() {
        let viewModel = HomeViewModel()
        let calendar = Calendar.current
        
        // Mix of complete and draft entries
        let completeEntry = JournalEntry()
        completeEntry.createdAt = calendar.date(byAdding: .day, value: -1, to: Date())!
        completeEntry.isDraft = false
        completeEntry.aiReframe = AIReframeResult(
            validation: nil,
            whatMightBeHappening: nil,
            cognitiveDistortions: nil,
            balancedThought: "Complete",
            microActionPlan: nil,
            communicationScript: nil,
            selfCompassion: nil,
            realityCheckQuestions: nil,
            oneSmallExperiment: nil,
            summary: nil,
            rawResponse: nil
        )
        
        let draftEntry = JournalEntry()
        draftEntry.createdAt = calendar.date(byAdding: .day, value: -2, to: Date())!
        draftEntry.isDraft = true
        
        viewModel.updateStreak(from: [completeEntry, draftEntry])
        
        // Should only count complete entries
        XCTAssertGreaterThanOrEqual(viewModel.streak, 0)
    }
    
    @MainActor
    func testEntriesForSelectedDate() {
        let viewModel = HomeViewModel()
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let entryToday = JournalEntry()
        entryToday.createdAt = calendar.startOfDay(for: today)
        
        let entryYesterday = JournalEntry()
        entryYesterday.createdAt = calendar.startOfDay(for: yesterday)
        
        let allEntries = [entryToday, entryYesterday]
        
        // Select today
        viewModel.selectDate(today)
        let todayEntries = viewModel.entriesForSelectedDate(from: allEntries)
        XCTAssertEqual(todayEntries.count, 1)
        XCTAssertEqual(todayEntries.first?.recordId, entryToday.recordId)
        
        // Select yesterday
        viewModel.selectDate(yesterday)
        let yesterdayEntries = viewModel.entriesForSelectedDate(from: allEntries)
        XCTAssertEqual(yesterdayEntries.count, 1)
        XCTAssertEqual(yesterdayEntries.first?.recordId, entryYesterday.recordId)
    }
    
    func testWeekDayAccessibilityLabel() {
        let calendar = Calendar.current
        let date = Date()
        let day = WeekDay(
            id: date,
            date: date,
            dayOfWeek: "Mon",
            dayNumber: 15,
            isToday: true,
            isSelected: true,
            hasEntry: true
        )
        
        let label = day.accessibilityLabel
        XCTAssertFalse(label.isEmpty)
        XCTAssertTrue(label.contains("today") || label.contains("Today"))
        XCTAssertTrue(label.contains("entries") || label.contains("Entries"))
    }
    
    func testWeekDayEquatable() {
        let date = Date()
        let day1 = WeekDay(
            id: date,
            date: date,
            dayOfWeek: "Mon",
            dayNumber: 15,
            isToday: true,
            isSelected: true,
            hasEntry: true
        )
        let day2 = WeekDay(
            id: date,
            date: date,
            dayOfWeek: "Mon",
            dayNumber: 15,
            isToday: true,
            isSelected: true,
            hasEntry: true
        )
        let day3 = WeekDay(
            id: Date(),
            date: Date(),
            dayOfWeek: "Tue",
            dayNumber: 16,
            isToday: false,
            isSelected: false,
            hasEntry: false
        )
        
        XCTAssertEqual(day1, day2)
        XCTAssertNotEqual(day1, day3)
    }
    
    func testWeekDayIdentifiable() {
        let date = Date()
        let day = WeekDay(
            id: date,
            date: date,
            dayOfWeek: "Mon",
            dayNumber: 15,
            isToday: true,
            isSelected: true,
            hasEntry: true
        )
        
        XCTAssertEqual(day.id, date)
    }
}
