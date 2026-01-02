// File: Services/EntitlementsManager.swift
import Foundation
import StoreKit

@MainActor
final class EntitlementsManager: ObservableObject {
    @Published private(set) var isPro: Bool = false
    @Published private(set) var proProduct: Product?

    private let productId: String
    private var updatesTask: Task<Void, Never>?

    init(productId: String = "reframejournal.pro.monthly") {
        self.productId = productId
        updatesTask = Task { await observeTransactions() }
        Task { await refreshEntitlements() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async -> Bool {
        do {
            let products = try await Product.products(for: [productId])
            proProduct = products.first
            return proProduct != nil
        } catch {
            proProduct = nil
            return false
        }
    }

    func purchase() async throws {
        guard let product = proProduct else {
            throw EntitlementError.productUnavailable
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verify(verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? verify(result), transaction.productID == productId {
                hasPro = true
                break
            }
        }
        isPro = hasPro
    }

    private func observeTransactions() async {
        for await update in Transaction.updates {
            do {
                let transaction = try verify(update)
                await transaction.finish()
                await refreshEntitlements()
            } catch {
                continue
            }
        }
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw EntitlementError.failedVerification
        }
    }

    enum EntitlementError: LocalizedError {
        case productUnavailable
        case failedVerification

        var errorDescription: String? {
            switch self {
            case .productUnavailable:
                return "Product unavailable."
            case .failedVerification:
                return "Purchase could not be verified."
            }
        }
    }
}
