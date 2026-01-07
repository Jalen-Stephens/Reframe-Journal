import SwiftUI

private struct NotesPalettePreview: View {
    @Environment(\.notesPalette) private var notesPalette

    var body: some View {
        ZStack {
            notesPalette.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text("Notes Theme")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(notesPalette.textPrimary)

                GlassCard(emphasized: true) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Primary text")
                            .foregroundStyle(notesPalette.textPrimary)
                        Text("Secondary text")
                            .foregroundStyle(notesPalette.textSecondary)
                        Text("Tertiary text")
                            .foregroundStyle(notesPalette.textTertiary)
                    }
                }

                HStack(spacing: 12) {
                    GlassPill {
                        Text("Pill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(notesPalette.textSecondary)
                    }
                    GlassIconButton(icon: .chevronLeft, accessibilityLabel: "Back") {}
                }

                Divider()
                    .background(notesPalette.separator)
            }
            .padding(20)
        }
    }
}

#Preview("Notes Light") {
    NotesPalettePreview()
        .preferredColorScheme(.light)
        .notesTheme()
}

#Preview("Notes Dark") {
    NotesPalettePreview()
        .preferredColorScheme(.dark)
        .notesTheme()
}
