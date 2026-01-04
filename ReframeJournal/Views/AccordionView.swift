import SwiftUI

struct AccordionView<Header: View, Content: View>: View {
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
        .cardSurface(cornerRadius: 12, shadow: false)
    }
}
