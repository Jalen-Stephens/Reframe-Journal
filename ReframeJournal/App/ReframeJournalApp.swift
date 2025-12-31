import SwiftUI

@main
struct ReframeJournalApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var router = AppRouter()
    @StateObject private var themeManager = ThemeManager()
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue

    private var appAppearance: AppAppearance {
        get { AppAppearance(rawValue: appAppearanceRaw) ?? .system }
        set { appAppearanceRaw = newValue.rawValue }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(router)
                .environmentObject(themeManager)
                .preferredColorScheme(overrideScheme)
        }
    }

    private var overrideScheme: ColorScheme? {
        // nil means "do not override", keeping Match System identical to the device appearance.
        switch appAppearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
