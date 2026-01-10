// File: Services/MockRewardedAdManager.swift
import Foundation

/// Mock implementation of RewardedAdManager for test environment
/// This avoids importing GoogleMobileAds SDK which crashes during test initialization
@MainActor
final class MockRewardedAdManager: ObservableObject, RewardedAdManagerProtocol {
    
    init() {}
    
    func loadAd() async {
        // No-op in mock
    }
    
    func presentAd() async throws -> Bool {
        // Always fail in mock
        throw RewardedAdError.noAdAvailable
    }
}
