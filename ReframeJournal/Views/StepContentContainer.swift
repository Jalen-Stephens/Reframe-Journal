import SwiftUI

struct StepContentContainer<Content: View>: View {
    let title: String
    let step: Int
    let total: Int
    let content: Content

    init(title: String, step: Int, total: Int, @ViewBuilder content: () -> Content) {
        self.title = title
        self.step = step
        self.total = total
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StepHeaderView(title: title, step: step, total: total)
                    content
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
        }
    }
}
