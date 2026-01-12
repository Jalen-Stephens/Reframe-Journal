import SwiftUI

struct EntryListItemView: View {
    @Environment(\.notesPalette) private var notesPalette

    let entry: JournalEntry
    let onTap: () -> Void

    var body: some View {
        let status = entry.completionStatus
        Button(action: onTap) {
            GlassCard(padding: AppTheme.cardPaddingCompact) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(titleLabel(for: entry))
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            // Entry type indicator
                            Text(entry.entryType.displayName)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(notesPalette.textTertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                                )
                        }
                        
                        HStack(spacing: 8) {
                            Text(DateUtils.formatRelativeDateTime(DateUtils.isoString(from: entry.createdAt)))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            
                            // Status badge
                            if let entryStatus = entry.entryStatus {
                                HStack(spacing: 4) {
                                    Image(systemName: entryStatus.icon)
                                        .font(.system(size: 10))
                                    Text(entryStatus.displayName)
                                        .font(.caption2)
                                }
                                .foregroundStyle(notesPalette.textTertiary)
                            }
                        }
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
        .accessibilityLabel("\(titleLabel(for: entry)). \(entry.entryType.displayName). \(status.accessibilityLabel).")
    }
    
    @Environment(\.colorScheme) private var colorScheme

    private func titleLabel(for entry: JournalEntry) -> String {
        if let title = entry.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        let situation = entry.situationText.trimmingCharacters(in: .whitespacesAndNewlines)
        if situation.isEmpty {
            return "New Entry"
        }
        let firstLine = situation.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? situation
        return firstLine
    }
}
