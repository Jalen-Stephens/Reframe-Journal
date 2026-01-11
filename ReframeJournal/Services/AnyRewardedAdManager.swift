// File: Services/AnyRewardedAdManager.swift
import Foundation
import Combine

/// Type-erased wrapper for RewardedAdManagerProtocol
/// This allows us to store either RewardedAdManager or MockRewardedAdManager in the same @StateObject
@MainActor
final class AnyRewardedAdManager: ObservableObject {
    private let _loadAd: () async -> Void
    private let _presentAd: () async throws -> Bool
    private var cancellable: AnyCancellable?
    
    init<T: RewardedAdManagerProtocol>(_ manager: T) {
        self._loadAd = manager.loadAd
        self._presentAd = manager.presentAd
        
        // Forward objectWillChange from wrapped manager
        self.cancellable = (manager.objectWillChange as? ObservableObjectPublisher)?
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
    
    func loadAd() async {
        await _loadAd()
    }
    
    func presentAd() async throws -> Bool {
        try await _presentAd()
    }
}
