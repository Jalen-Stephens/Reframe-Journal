import SwiftUI

struct AccordionView<Header: View, Content: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let header: Header
    let content: Content
    @Binding var isExpanded: Bool

    init(isExpanded: Binding<Bool>, @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.header = header()
        self.content = content()
        _isExpanded = isExpanded
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
                .padding(.top, 8)
        } label: {
            header
        }
        .padding(12)
        .background(themeManager.theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
