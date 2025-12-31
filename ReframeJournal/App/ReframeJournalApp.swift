import SwiftUI

@main
struct ReframeJournalApp: App {
    @StateObject private var thoughtStore: ThoughtRecordStore
    @StateObject private var appState: AppState
    @StateObject private var router = AppRouter()
    @StateObject private var themeManager = ThemeManager()
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let store = ThoughtRecordStore()
        _thoughtStore = StateObject(wrappedValue: store)
        _appState = StateObject(wrappedValue: AppState(repository: ThoughtRecordRepository(store: store)))
    }

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
                .environmentObject(thoughtStore)
                .preferredColorScheme(overrideScheme)
                .onChange(of: scenePhase) { phase in
                    if phase == .inactive || phase == .background {
                        Task { await thoughtStore.flushPendingWrites() }
                    }
                }
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
