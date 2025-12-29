import SwiftUI

@main
struct ReframeJournalApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var router = AppRouter()
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.colorScheme) private var colorScheme
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
                .onAppear {
                    themeManager.resolvedScheme = resolveScheme()
                }
                .onChange(of: colorScheme) { _ in
                    themeManager.resolvedScheme = resolveScheme()
                }
                .onChange(of: appAppearanceRaw) { _ in
                    themeManager.resolvedScheme = resolveScheme()
                }
                .preferredColorScheme(overrideScheme)
        }
    }

    private func resolveScheme() -> ColorScheme {
        switch appAppearance {
        case .system:
            return colorScheme
        case .light:
            return .light
        case .dark:
            return .dark
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
