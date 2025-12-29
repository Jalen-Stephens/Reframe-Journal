import SwiftUI

@main
struct ReframeJournalApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var router = AppRouter()
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.colorScheme) private var colorScheme

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(router)
                .environmentObject(themeManager)
                .onAppear {
                    themeManager.resolvedScheme = resolveScheme()
                }
                .onChange(of: colorScheme) { _ in
                    themeManager.resolvedScheme = resolveScheme()
                }
                .onChange(of: themeManager.themePreference) { _ in
                    themeManager.resolvedScheme = resolveScheme()
                }
                .preferredColorScheme(themeManager.preferredColorScheme())
        }
    }

    private func resolveScheme() -> ColorScheme {
        switch themeManager.themePreference {
        case .system:
            return colorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
