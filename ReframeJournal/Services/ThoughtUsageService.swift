import Foundation

@MainActor
final class ThoughtUsageService {
    private let usageDateKey = "thoughtUsageDate"
    private let usageCountKey = "thoughtUsageCount"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        resetIfNewDay()
    }

    var hasUnlimitedThoughts: Bool {
        // TODO: Hook up StoreKit subscription status for unlimited thoughts.
        false
    }

    func getTodayCount() -> Int {
        resetIfNewDay()
        return userDefaults.integer(forKey: usageCountKey)
    }

    func incrementTodayCount() {
        resetIfNewDay()
        let count = userDefaults.integer(forKey: usageCountKey)
        userDefaults.set(count + 1, forKey: usageCountKey)
    }

    func canCreateThought() -> Bool {
        if hasUnlimitedThoughts {
            return true
        }
        return getTodayCount() < 3
    }

    func resetIfNewDay() {
        let today = Self.localDayString(for: Date())
        let storedDate = userDefaults.string(forKey: usageDateKey)
        if storedDate != today {
            userDefaults.set(today, forKey: usageDateKey)
            userDefaults.set(0, forKey: usageCountKey)
        }
    }

    private static func localDayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
