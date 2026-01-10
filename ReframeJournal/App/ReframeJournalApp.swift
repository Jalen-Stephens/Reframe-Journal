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
    @StateObject private var rewardedAdManager: RewardedAdManager

    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Detect test environment
        let isTestEnvironment = NSClassFromString("XCTestCase") != nil
        
        // Initialize SwiftData ModelContainer
        do {
            let container = try ModelContainerConfig.makeContainer()
            self.modelContainer = container
            
            // Initialize AppState with the model context
            let context = container.mainContext
            _appState = StateObject(wrappedValue: AppState(modelContext: context))
        } catch {
            // In test environment, use a minimal in-memory container
            if isTestEnvironment {
                print("⚠️ Test environment detected, using in-memory container")
                do {
                    let config = ModelConfiguration(isStoredInMemoryOnly: true)
                    let container = try ModelContainer(
                        for: JournalEntry.self, ValuesProfileData.self,
                        configurations: config
                    )
                    self.modelContainer = container
                    let context = container.mainContext
                    _appState = StateObject(wrappedValue: AppState(modelContext: context))
                } catch {
                    fatalError("Failed to initialize fallback ModelContainer: \(error)")
                }
            } else {
                fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
            }
        }
        
        let limits = LimitsManager()
        // Skip RewardedAdManager initialization in test environment to avoid GoogleMobileAds crash
        let rewarded = RewardedAdManager(adUnitID: isTestEnvironment ? "" : RewardedAdManager.loadAdUnitID())
        _limitsManager = StateObject(wrappedValue: limits)
        _rewardedAdManager = StateObject(wrappedValue: rewarded)
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
