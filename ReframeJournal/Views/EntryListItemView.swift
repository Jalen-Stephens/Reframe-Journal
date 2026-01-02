import SwiftUI

struct EntryListItemView: View {
    let entry: ThoughtRecord
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(titleLabel(for: entry))
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(DateUtils.formatRelativeDateTime(entry.createdAt))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func titleLabel(for record: ThoughtRecord) -> String {
        if let title = record.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        let situation = record.situationText.trimmingCharacters(in: .whitespacesAndNewlines)
        if situation.isEmpty {
            return "New Entry"
        }
        let firstLine = situation.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? situation
        if firstLine.count > 40 {
            let index = firstLine.index(firstLine.startIndex, offsetBy: 40)
            return String(firstLine[..<index])
        }
        return firstLine
    }
}
