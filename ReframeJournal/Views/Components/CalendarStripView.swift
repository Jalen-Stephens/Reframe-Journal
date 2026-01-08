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
            
            // Entry indicator pawprint (for completed entries)
            if day.hasEntry {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(entryIndicatorColor(for: day))
                    .padding(.top, 2)
            } else {
                // Spacer to keep alignment consistent
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(Color.clear)
                    .padding(.top, 2)
            }
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
    
    private func entryIndicatorColor(for day: WeekDay) -> Color {
        if day.isSelected {
            // When selected, use a more visible color
            return notesPalette.colorScheme == .dark 
                ? Color.white.opacity(0.9)
                : Color.black.opacity(0.8)
        }
        // Use accent color or a subtle color for unselected days
        return notesPalette.accent.opacity(0.7)
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
    
    ZStack {
        Color("NotesBackground")
            .ignoresSafeArea()
        CalendarStripView(weekDays: days) { _ in }
            .notesTheme()
    }
}
