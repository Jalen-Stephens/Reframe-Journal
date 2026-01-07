import Foundation

@MainActor
final class ThoughtUsageService {
    private let usageDateKey = "thoughtUsageDate"
    private let usageCountKey = "thoughtUsageCount"
    private let usageIdsKey = "thoughtUsageIds"
    private let devDisableLimitKey = "devDisableThoughtLimit"
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
        if let ids = userDefaults.stringArray(forKey: usageIdsKey) {
            return ids.count
        }
        return userDefaults.integer(forKey: usageCountKey)
    }

    @discardableResult
    func incrementTodayCount(recordId: String, createdAt: String? = nil) -> Bool {
        resetIfNewDay()
        if let createdAt, let createdDate = DateUtils.parseIso(createdAt) {
            let today = Self.localDayString(for: Date())
            let createdDay = Self.localDayString(for: createdDate)
            if createdDay != today {
                return false
            }
        }
        var ids = userDefaults.stringArray(forKey: usageIdsKey) ?? []
        guard !ids.contains(recordId) else { return false }
        ids.append(recordId)
        userDefaults.set(ids, forKey: usageIdsKey)
        userDefaults.set(ids.count, forKey: usageCountKey)
        return true
    }

    func canCreateThought() -> Bool {
        if hasUnlimitedThoughts {
            return true
        }
        if isDevLimitDisabled {
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
            userDefaults.set([], forKey: usageIdsKey)
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

    private var isDevLimitDisabled: Bool {
        userDefaults.bool(forKey: devDisableLimitKey)
    }
}
