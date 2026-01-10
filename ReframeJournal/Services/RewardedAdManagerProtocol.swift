// File: Services/RewardedAdManagerProtocol.swift
import Foundation

/// Protocol that abstracts rewarded ad functionality
/// This allows us to use a mock implementation in tests without importing GoogleMobileAds
@MainActor
protocol RewardedAdManagerProtocol: ObservableObject {
    func loadAd() async
    func presentAd() async throws -> Bool
}

enum RewardedAdError: LocalizedError {
    case noAdAvailable
    case noViewController
    case presentationFailed

    var errorDescription: String? {
        switch self {
        case .noAdAvailable:
            return "Ad unavailable. Try again later or upgrade to Pro."
        case .noViewController:
            return "Ad unavailable. Try again later or upgrade to Pro."
        case .presentationFailed:
            return "Ad unavailable. Try again later or upgrade to Pro."
        }
    }
}
