// File: Views/Components/CalendarStripView.swift
// Horizontal week calendar strip inspired by Stoic app design

import SwiftUI

struct CalendarStripView: View {
    @Environment(\.notesPalette) private var notesPalette
    
    let weekDays: [WeekDay]
    let onSelectDate: (Date) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(weekDays) { day in
                    dayView(for: day)
                        .onTapGesture {
                            onSelectDate(day.date)
                        }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            
            // Subtle divider
            Rectangle()
                .fill(notesPalette.separator)
                .frame(height: 0.5)
                .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Day View
    
    @ViewBuilder
    private func dayView(for day: WeekDay) -> some View {
        let isSelected = day.isSelected
        
        VStack(spacing: 4) {
            // Day of week abbreviation
            Text(day.dayOfWeek)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(dayOfWeekColor(for: day))
                .textCase(.uppercase)
            
            // Day number
            Text("\(day.dayNumber)")
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(dayNumberColor(for: day))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(notesPalette.colorScheme == .dark 
                          ? Color.white.opacity(0.12) 
                          : Color.black.opacity(0.08))
                    .padding(.horizontal, 2)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    // MARK: - Colors
    
    private func dayOfWeekColor(for day: WeekDay) -> Color {
        if day.isSelected {
            return notesPalette.textPrimary
        }
        return notesPalette.textTertiary
    }
    
    private func dayNumberColor(for day: WeekDay) -> Color {
        if day.isSelected {
            return notesPalette.textPrimary
        }
        if day.isToday {
            return notesPalette.textPrimary
        }
        return notesPalette.textTertiary
    }
}

// MARK: - Preview

#Preview("Calendar Strip") {
    let calendar = Calendar.current
    let today = Date()
    
    let days: [WeekDay] = (0..<7).compactMap { offset in
        guard let date = calendar.date(byAdding: .day, value: offset - 3, to: today) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return WeekDay(
            id: date,
            date: date,
            dayOfWeek: formatter.string(from: date),
            dayNumber: calendar.component(.day, from: date),
            isToday: calendar.isDateInToday(date),
            isSelected: calendar.isDateInToday(date),
            hasEntry: offset % 2 == 0
        )
    }
    
    CalendarStripView(weekDays: days) { _ in }
        .notesTheme()
        .background(Color("NotesBackground"))
}
