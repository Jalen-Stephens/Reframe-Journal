// File: App/ReframeJournalApp.swift
import SwiftUI

@main
struct ReframeJournalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var thoughtStore: ThoughtRecordStore
    @StateObject private var appState: AppState
    @StateObject private var router = AppRouter()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var entitlementsManager = EntitlementsManager()
    @StateObject private var limitsManager: LimitsManager
    @StateObject private var rewardedAdManager: RewardedAdManager

    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let store = ThoughtRecordStore()
        let limits = LimitsManager()
        let rewarded = RewardedAdManager(adUnitID: RewardedAdManager.loadAdUnitID())
        _thoughtStore = StateObject(wrappedValue: store)
        _appState = StateObject(wrappedValue: AppState(repository: ThoughtRecordRepository(store: store)))
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
                .environmentObject(themeManager)
                .environmentObject(thoughtStore)
                .environmentObject(entitlementsManager)
                .environmentObject(limitsManager)
                .environmentObject(rewardedAdManager)
                .preferredColorScheme(overrideScheme)
                .onChange(of: scenePhase) { phase in
                    if phase == .inactive || phase == .background {
                        Task { @MainActor in
                            await thoughtStore.flushPendingWrites()
                        }
                    }
                }
        }
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
