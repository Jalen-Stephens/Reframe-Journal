import SwiftUI

struct EntryListItemView: View {
    @Environment(\.notesPalette) private var notesPalette

    let entry: ThoughtRecord
    let onTap: () -> Void

    var body: some View {
        let status = entry.completionStatus
        Button(action: onTap) {
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(titleLabel(for: entry))
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(DateUtils.formatRelativeDateTime(entry.createdAt))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    AppIconView(icon: status.icon, size: 20)
                        .foregroundStyle(notesPalette.textTertiary)
                        .frame(width: 22, height: 22)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.2), value: status)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(titleLabel(for: entry)). \(status.accessibilityLabel).")
    }

    private func titleLabel(for record: ThoughtRecord) -> String {
        if let title = record.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        let situation = record.situationText.trimmingCharacters(in: .whitespacesAndNewlines)
        if situation.isEmpty {
            return "New Entry"
        }
        // Get first line and remove any newlines/line breaks
        let firstLine = situation.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? situation
        return firstLine
    }
}
