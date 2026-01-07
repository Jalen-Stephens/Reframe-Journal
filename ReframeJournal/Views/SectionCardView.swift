import SwiftUI

struct SectionCardView<Content: View>: View {
    @Environment(\.notesPalette) private var notesPalette

    let title: String
    var subtitle: String? = nil
    var collapsible: Bool = false
    let content: Content

    @State private var isExpanded: Bool = true

    init(title: String, subtitle: String? = nil, collapsible: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.collapsible = collapsible
        self.content = content()
        _isExpanded = State(initialValue: true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                if collapsible {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(notesPalette.textPrimary)
                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(notesPalette.textSecondary)
                        }
                    }
                    Spacer()
                    if collapsible {
                        Text(isExpanded ? "v" : ">")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(notesPalette.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)

            if !collapsible || isExpanded {
                content
            }
        }
        .padding(14)
        .cardSurface(cornerRadius: 14)
    }
}
