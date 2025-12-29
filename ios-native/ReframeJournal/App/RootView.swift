import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.theme.background.ignoresSafeArea()
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .allEntries:
                            AllEntriesView()
                        case let .entryDetail(id):
                            EntryDetailView(entryId: id)
                        case let .thoughtResponseDetail(entryId, thoughtId):
                            ThoughtResponseDetailView(entryId: entryId, thoughtId: thoughtId)
                        case .wizardStep1:
                            DateTimeView()
                        case .wizardStep2:
                            SituationView()
                        case .wizardStep3:
                            AutomaticThoughtsView()
                        case .wizardStep4:
                            EmotionsView()
                        case .wizardStep5:
                            AdaptiveResponseView()
                        case .wizardStep6:
                            OutcomeView()
                        case .settings:
                            SettingsView()
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}
