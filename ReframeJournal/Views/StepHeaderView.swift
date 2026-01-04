import SwiftUI

struct StepHeaderView: View {
    @Environment(\.notesPalette) private var notesPalette

    let title: String
    let step: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(notesPalette.textPrimary)
            WizardProgressView(step: step, total: total)
        }
    }
}
