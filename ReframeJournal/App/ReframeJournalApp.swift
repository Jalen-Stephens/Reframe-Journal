// File: App/ReframeJournalApp.swift
// App entry point - now using SwiftData for persistence

import SwiftUI
import SwiftData

@main
struct ReframeJournalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // SwiftData ModelContainer
    private let modelContainer: ModelContainer
    
    @StateObject private var appState: AppState
    @StateObject private var router = AppRouter()
    @StateObject private var entitlementsManager = EntitlementsManager()
    @StateObject private var limitsManager: LimitsManager
    @StateObject private var rewardedAdManager: AnyRewardedAdManager

    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Detect test environment
        let isTestEnvironment = NSClassFromString("XCTestCase") != nil
        
        // Initialize SwiftData ModelContainer
        if isTestEnvironment {
            // Always use in-memory container for tests
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(
                    for: JournalEntry.self, ValuesProfileData.self, ValuesCategoryEntryData.self,
                    configurations: config
                )
                self.modelContainer = container
                let context = container.mainContext
                _appState = StateObject(wrappedValue: AppState(modelContext: context))
            } catch {
                fatalError("Failed to initialize test ModelContainer: \(error)")
            }
            
            // Use mock RewardedAdManager to avoid GoogleMobileAds issues
            let mock = MockRewardedAdManager()
            _rewardedAdManager = StateObject(wrappedValue: AnyRewardedAdManager(mock))
        } else {
            // Production initialization
            do {
                let container = try ModelContainerConfig.makeContainer()
                self.modelContainer = container
                let context = container.mainContext
                _appState = StateObject(wrappedValue: AppState(modelContext: context))
            } catch {
                fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
            }
            
            let rewarded = RewardedAdManager(adUnitID: RewardedAdManager.loadAdUnitID())
            _rewardedAdManager = StateObject(wrappedValue: AnyRewardedAdManager(rewarded))
        }
        
        _limitsManager = StateObject(wrappedValue: LimitsManager())
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
                .environmentObject(entitlementsManager)
                .environmentObject(limitsManager)
                .environmentObject(rewardedAdManager)
                .preferredColorScheme(overrideScheme)
                .notesTheme()
        }
        .modelContainer(modelContainer)
    }

    private var overrideScheme: ColorScheme? {
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
