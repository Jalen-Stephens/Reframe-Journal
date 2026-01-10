// File: Services/RewardedAdManager.swift
import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdManager: NSObject, ObservableObject {
    static let testAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    private static let adUnitInfoKey = "ADMOB_REWARDED_AD_UNIT_ID"

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

    private let adUnitID: String
    private var rewardedAd: GADRewardedAd?
    private var isLoading: Bool = false
    private var continuation: CheckedContinuation<Bool, Error>?
    private var didEarnReward: Bool = false

    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        // Skip ad loading in test environment or if adUnitID is empty
        if !adUnitID.isEmpty && NSClassFromString("XCTestCase") == nil {
            Task { await loadAd() }
        }
    }

    static func loadAdUnitID() -> String {
        if let rawValue = Bundle.main.object(forInfoDictionaryKey: adUnitInfoKey) as? String {
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.hasPrefix("$(") {
                return trimmed
            }
        }
#if DEBUG
        return testAdUnitID
#else
        return ""
#endif
    }

    func loadAd() async {
        // Skip entirely in test environment
        guard NSClassFromString("XCTestCase") == nil else {
            return
        }
        guard !isLoading else { return }
        guard !adUnitID.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }

        do {
#if DEBUG
            print("RewardedAdManager: LOAD START")
#endif
            let ad = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GADRewardedAd, Error>) in
                GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { ad, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let ad else {
                        continuation.resume(throwing: RewardedAdError.noAdAvailable)
                        return
                    }
                    continuation.resume(returning: ad)
                }
            }
            rewardedAd = ad
#if DEBUG
            print("RewardedAdManager: LOAD SUCCESS")
#endif
        } catch {
            rewardedAd = nil
#if DEBUG
            print("RewardedAdManager: LOAD FAIL \(error)")
#endif
        }
    }

    func presentAd() async throws -> Bool {
        // Skip entirely in test environment
        guard NSClassFromString("XCTestCase") == nil else {
            throw RewardedAdError.noAdAvailable
        }
        
        if rewardedAd == nil {
            await loadAd()
        }
        guard let ad = rewardedAd else {
            throw RewardedAdError.noAdAvailable
        }
        guard let viewController = UIViewController.topMostViewController() else {
            throw RewardedAdError.noViewController
        }

        didEarnReward = false
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            self.continuation = continuation
            ad.fullScreenContentDelegate = self
#if DEBUG
            print("RewardedAdManager: PRESENT")
#endif
            ad.present(fromRootViewController: viewController) { [weak self] in
                self?.didEarnReward = true
#if DEBUG
                print("RewardedAdManager: REWARD EARNED")
#endif
            }
        }
    }

    private func finishPresentation(with result: Result<Bool, Error>) {
        let continuation = continuation
        self.continuation = nil
        rewardedAd = nil
        Task { await loadAd() }
        switch result {
        case .success(let rewarded):
            continuation?.resume(returning: rewarded)
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
    }
}

extension RewardedAdManager: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
#if DEBUG
            print("RewardedAdManager: DISMISS")
#endif
            self.finishPresentation(with: .success(self.didEarnReward))
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
#if DEBUG
            print("RewardedAdManager: PRESENT FAIL \(error)")
#endif
            self.finishPresentation(with: .failure(RewardedAdError.presentationFailed))
        }
    }
}

private extension UIViewController {
    static func topMostViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        guard let window = scenes
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return nil
        }

        return topMostViewController(from: window.rootViewController)
    }

    static func topMostViewController(from root: UIViewController?) -> UIViewController? {
        if let navigation = root as? UINavigationController {
            return topMostViewController(from: navigation.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topMostViewController(from: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topMostViewController(from: presented)
        }
        return root
    }
}
