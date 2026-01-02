// File: Services/LimitsManager.swift
import Foundation

@MainActor
final class LimitsManager: ObservableObject {
    enum LimitError: LocalizedError {
        case dailyThoughtLimitReached
        case dailyReframeLimitReached
        case rollingWindowLimitReached

        var errorDescription: String? {
            switch self {
            case .dailyThoughtLimitReached:
                return "You've reached today's free entry limit. Upgrade to Pro."
            case .dailyReframeLimitReached, .rollingWindowLimitReached:
                return "You've hit today's AI limit. Try again tomorrow."
            }
        }
    }

    private let storage: UserDefaults
    private let calendar: Calendar
    private let nowProvider: () -> Date

    @Published private(set) var dailyThoughtCount: Int
    @Published private(set) var dailyReframeCount: Int
    @Published private(set) var recentReframeCount: Int

    private let freeDailyThoughtLimit = 3
    private let dailyReframeLimit = 30
    private let rollingWindowLimit = 5
    private let rollingWindowSeconds: TimeInterval = 10 * 60

    private let lastResetKey = "limits.lastResetDate"
    private let thoughtCountKey = "limits.dailyThoughtCount"
    private let reframeCountKey = "limits.dailyReframeCount"
    private let reframeTimestampsKey = "limits.reframeTimestamps"

    private let dateFormatter: ISO8601DateFormatter

    init(
        storage: UserDefaults = .standard,
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.storage = storage
        self.calendar = calendar
        self.nowProvider = nowProvider
        self.dailyThoughtCount = storage.integer(forKey: thoughtCountKey)
        self.dailyReframeCount = storage.integer(forKey: reframeCountKey)
        self.recentReframeCount = 0
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.dateFormatter = formatter
        refreshIfNeeded()
    }

    func assertCanCreateThought(isPro: Bool) throws {
        refreshIfNeeded()
        guard isPro || dailyThoughtCount < freeDailyThoughtLimit else {
            throw LimitError.dailyThoughtLimitReached
        }
    }

    func recordThought() {
        refreshIfNeeded()
        dailyThoughtCount += 1
        storage.set(dailyThoughtCount, forKey: thoughtCountKey)
    }

    func assertCanGenerateReframe() throws {
        refreshIfNeeded()
        let recentCount = pruneAndCountRecentReframes()
        recentReframeCount = recentCount
        guard dailyReframeCount < dailyReframeLimit else {
            throw LimitError.dailyReframeLimitReached
        }
        guard recentCount < rollingWindowLimit else {
            throw LimitError.rollingWindowLimitReached
        }
    }

    func recordReframe() {
        refreshIfNeeded()
        dailyReframeCount += 1
        storage.set(dailyReframeCount, forKey: reframeCountKey)
        var timestamps = loadReframeTimestamps()
        timestamps.append(nowProvider())
        saveReframeTimestamps(timestamps)
        recentReframeCount = pruneAndCountRecentReframes()
    }

    func refreshIfNeeded() {
        let now = nowProvider()
        let startOfDay = calendar.startOfDay(for: now)
        guard let lastReset = loadLastResetDate() else {
            persistResetDate(startOfDay)
            return
        }

        if lastReset > now || !calendar.isDate(lastReset, inSameDayAs: now) {
            resetCounts(startOfDay: startOfDay)
        }
    }

    private func resetCounts(startOfDay: Date) {
        dailyThoughtCount = 0
        dailyReframeCount = 0
        recentReframeCount = 0
        storage.set(0, forKey: thoughtCountKey)
        storage.set(0, forKey: reframeCountKey)
        saveReframeTimestamps([])
        persistResetDate(startOfDay)
    }

    private func persistResetDate(_ date: Date) {
        storage.set(dateFormatter.string(from: date), forKey: lastResetKey)
    }

    private func loadLastResetDate() -> Date? {
        guard let string = storage.string(forKey: lastResetKey) else { return nil }
        return dateFormatter.date(from: string)
    }

    private func loadReframeTimestamps() -> [Date] {
        guard let strings = storage.array(forKey: reframeTimestampsKey) as? [String] else {
            return []
        }
        return strings.compactMap { dateFormatter.date(from: $0) }
    }

    private func saveReframeTimestamps(_ timestamps: [Date]) {
        let strings = timestamps.map { dateFormatter.string(from: $0) }
        storage.set(strings, forKey: reframeTimestampsKey)
    }

    private func pruneAndCountRecentReframes() -> Int {
        let now = nowProvider()
        let cutoff = now.addingTimeInterval(-rollingWindowSeconds)
        let timestamps = loadReframeTimestamps().filter { $0 >= cutoff }
        saveReframeTimestamps(timestamps)
        return timestamps.count
    }
}
