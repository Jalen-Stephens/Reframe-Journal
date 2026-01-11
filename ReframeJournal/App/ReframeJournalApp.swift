// File: App/ReframeJournalApp.swift
// App entry point - now using SwiftData for persistence

import SwiftUI
import SwiftData
import UIKit

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

    init() {
        // Initialize PostHog analytics (skips in test environment)
        AnalyticsService.shared.initialize()
        // Initialize SwiftData ModelContainer
        do {
            let container = try ModelContainerConfig.makeContainer()
            self.modelContainer = container
            
            // Initialize AppState with the model context
            let context = container.mainContext
            _appState = StateObject(wrappedValue: AppState(modelContext: context))
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
        
        let limits = LimitsManager()
        let rewarded = RewardedAdManager(adUnitID: RewardedAdManager.loadAdUnitID())
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
                .onAppear {
                    Task { @MainActor in
                        // Set initial user properties
                        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
                        AnalyticsService.shared.setUserProperties([
                            "device_type": deviceType,
                            "is_pro_user": entitlementsManager.isPro
                        ])
                        AnalyticsService.shared.trackEvent("app_opened")
                    }
                }
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
