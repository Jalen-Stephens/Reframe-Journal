import SwiftUI

struct SlimMeterRowView: View {
    @Environment(\.notesPalette) private var notesPalette

    let label: String
    let value: Int
    var boldLabel: Bool = false
    var labelLines: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: boldLabel ? .semibold : .regular))
                .foregroundColor(notesPalette.textPrimary)
                .lineLimit(labelLines)
            GeometryReader { proxy in
                let width = proxy.size.width * CGFloat(Metrics.clampPercent(value)) / 100.0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(notesPalette.muted)
                        .frame(height: 6)
                    Capsule()
                        .fill(notesPalette.accent)
                        .frame(width: width, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
