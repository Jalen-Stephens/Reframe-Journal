import SwiftUI

enum Route: Hashable {
    case allEntries
    case entryDetail(id: String)
    case thoughtResponseDetail(entryId: String, thoughtId: String)
    case aiReframeResult(entryId: String, action: AIReframeAction)
    case wizardStep1
    case wizardStep2
    case wizardStep3
    case wizardStep4
    case wizardStep5
    case wizardStep6
    case settings
}

enum AIReframeAction: Hashable {
    case view
    case generate
    case regenerate
}

final class AppRouter: ObservableObject {
    @Published var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
