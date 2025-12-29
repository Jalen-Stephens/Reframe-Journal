import Foundation

enum DateUtils {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func nowIso() -> String {
        isoFormatter.string(from: Date())
    }

    static func isoString(from date: Date) -> String {
        isoFormatter.string(from: date)
    }

    static func parseIso(_ iso: String) -> Date? {
        if let date = isoFormatter.date(from: iso) {
            return date
        }
        let fallback = ISO8601DateFormatter()
        return fallback.date(from: iso)
    }

    static func formatRelativeDate(_ iso: String) -> String {
        guard let date = parseIso(iso) else {
            return iso
        }
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) else {
            return date.formatted(date: .numeric, time: .omitted)
        }

        if date >= startOfToday {
            return "Today"
        }
        if date >= startOfYesterday {
            return "Yesterday"
        }
        return date.formatted(date: .numeric, time: .omitted)
    }

    static func formatRelativeDateTime(_ iso: String) -> String {
        guard let date = parseIso(iso) else {
            return iso
        }
        let dateLabel = formatRelativeDate(iso)
        let timeLabel = date.formatted(date: .omitted, time: .shortened)
        return "\(dateLabel) · \(timeLabel)"
    }
}
