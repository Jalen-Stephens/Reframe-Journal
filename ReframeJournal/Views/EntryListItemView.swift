import SwiftUI

struct EntryListItemView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let entry: ThoughtRecord
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(thoughtLabel(for: entry))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeManager.theme.textPrimary)
                    .lineLimit(2)
                Text(DateUtils.formatRelativeDateTime(entry.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.theme.textSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(cornerRadius: 12, shadow: false)
        }
        .buttonStyle(.plain)
    }

    private func thoughtLabel(for record: ThoughtRecord) -> String {
        let thought = record.automaticThoughts.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return thought.isEmpty ? "Untitled thought" : thought
    }
}
