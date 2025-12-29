import Foundation

enum Metrics {
    static func clampPercent(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    static func clampPercent(_ value: Double) -> Int {
        let rounded = Int(value.rounded())
        return clampPercent(rounded)
    }

    static func isRequiredTextValid(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
