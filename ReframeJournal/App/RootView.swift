import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            themeManager.theme.background.ignoresSafeArea()
            NavigationStack(path: $router.path) {
                HomeView(repository: appState.repository)
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .allEntries:
                            AllEntriesView(repository: appState.repository)
                        case let .entryDetail(id):
                            EntryDetailView(entryId: id, repository: appState.repository)
                        case let .thoughtResponseDetail(entryId, thoughtId):
                            ThoughtResponseDetailView(entryId: entryId, thoughtId: thoughtId, repository: appState.repository)
                        case let .aiReframeResult(entryId, action):
                            AIReframeResultView(entryId: entryId, repository: appState.repository, action: action)
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
        .onAppear {
            themeManager.resolvedScheme = colorScheme
        }
        .onChange(of: colorScheme) { newValue in
            themeManager.resolvedScheme = newValue
        }
    }
}
