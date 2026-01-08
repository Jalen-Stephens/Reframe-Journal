// File: ViewModels/HomeViewModel.swift
// ViewModel for redesigned Home screen with streak tracking and calendar selection

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Week Day Model

struct WeekDay: Identifiable, Equatable {
    let id: Date
    let date: Date
    let dayOfWeek: String // "Sun", "Mon", etc.
    let dayNumber: Int
    let isToday: Bool
    let isSelected: Bool
    let hasEntry: Bool
    
    var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        var label = formatter.string(from: date)
        if isToday { label += ", today" }
        if hasEntry { label += ", has entries" }
        return label
    }
}

// MARK: - Home ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var selectedDate: Date
    @Published private(set) var streak: Int = 0
    
    // MARK: - Private
    
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(initialDate: Date = Date()) {
        self.selectedDate = calendar.startOfDay(for: initialDate)
    }
    
    // MARK: - Computed Properties
    
    /// Time-of-day based greeting
    var greeting: String {
        let hour = calendar.component(.hour, from: Date())
        switch hour {
        case 0..<5:
            return "good night."
        case 5..<12:
            return "good morning."
        case 12..<17:
            return "good afternoon."
        case 17..<21:
            return "good evening."
        default:
            return "good night."
        }
    }
    
    /// Formatted day label for selected date (e.g., "FRIDAY")
    var selectedDayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate).uppercased()
    }
    
    /// Check if selected date is today
    var isSelectedToday: Bool {
        calendar.isDateInToday(selectedDate)
    }
    
    // MARK: - Week Generation
    
    /// Generate week days for the calendar strip centered on the current week
    func weekDays(entriesWithDates: Set<Date>) -> [WeekDay] {
        let today = calendar.startOfDay(for: Date())
        
        // Find the start of the week containing today
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }
        
        var days: [WeekDay] = []
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let dayOfWeek = formatter.string(from: date)
            let dayNumber = calendar.component(.day, from: date)
            let dayStart = calendar.startOfDay(for: date)
            
            let day = WeekDay(
                id: date,
                date: date,
                dayOfWeek: dayOfWeek,
                dayNumber: dayNumber,
                isToday: calendar.isDateInToday(date),
                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                hasEntry: entriesWithDates.contains(dayStart)
            )
            days.append(day)
        }
        return days
    }
    
    // MARK: - Actions
    
    func selectDate(_ date: Date) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = calendar.startOfDay(for: date)
        }
    }
    
    func selectToday() {
        selectDate(Date())
    }
    
    // MARK: - Streak Calculation
    
    /// Update streak based on entries with dates that have completed records
    func updateStreak(from entries: [JournalEntry]) {
        let completedDates = entries
            .filter { $0.completionStatus == .complete }
            .map { calendar.startOfDay(for: $0.createdAt) }
        
        streak = StreakCalculator.calculateStreak(from: completedDates, calendar: calendar)
    }
    
    // MARK: - Filtering
    
    /// Filter entries for the selected date
    func entriesForSelectedDate(from allEntries: [JournalEntry]) -> [JournalEntry] {
        allEntries.filter { entry in
            calendar.isDate(entry.createdAt, inSameDayAs: selectedDate)
        }
    }
    
    /// Get dates that have entries
    func datesWithEntries(from allEntries: [JournalEntry]) -> Set<Date> {
        Set(allEntries.map { calendar.startOfDay(for: $0.createdAt) })
    }
}

// MARK: - Streak Calculator

/// Clean, testable streak calculation
enum StreakCalculator {
    /// Calculate consecutive days with entries ending today (or yesterday if no entry today yet)
    /// - Parameters:
    ///   - dates: Array of dates that have completed entries
    ///   - calendar: Calendar to use for date calculations
    ///   - referenceDate: The reference "today" date (for testing)
    /// - Returns: The streak count
    static func calculateStreak(
        from dates: [Date],
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        // Normalize all dates to start of day and create a set
        let normalizedDates = Set(dates.map { calendar.startOfDay(for: $0) })
        
        let today = calendar.startOfDay(for: referenceDate)
        
        // Start checking from today, if today has an entry
        // If not, check if yesterday has one (streak can continue from yesterday)
        var checkDate = today
        var streakCount = 0
        
        // If today doesn't have an entry, the streak is 0
        // (You can't have a current streak if you haven't logged today)
        // UNLESS we want to show "streak at risk" - for now, we count only if today is logged
        // OR we're still in the same day window
        
        // Check from today backwards
        while true {
            if normalizedDates.contains(checkDate) {
                streakCount += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                    break
                }
                checkDate = previousDay
            } else {
                // No entry for this day, streak ends
                // Exception: if this is today and there's no entry yet, 
                // check if yesterday starts a streak
                if calendar.isDate(checkDate, inSameDayAs: today) && streakCount == 0 {
                    // Check yesterday
                    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                        break
                    }
                    checkDate = yesterday
                    // Continue the loop to check yesterday
                } else {
                    break
                }
            }
        }
        
        return streakCount
    }
}
