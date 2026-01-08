// File: Services/EntitlementsManager.swift
import Foundation
import StoreKit

// MARK: - Subscription Plan Enum

enum SubscriptionPlan: String, CaseIterable {
    case monthly = "reframejournal.pro.monthly"
    case yearly = "reframejournal.pro.yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Entitlements Manager

@MainActor
final class EntitlementsManager: ObservableObject {
    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [SubscriptionPlan: Product] = [:]
    @Published private(set) var selectedPlan: SubscriptionPlan = .yearly
    @Published private(set) var isLoading: Bool = false
    
    private var updatesTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var monthlyProduct: Product? {
        products[.monthly]
    }
    
    var yearlyProduct: Product? {
        products[.yearly]
    }
    
    /// For backward compatibility
    var proProduct: Product? {
        products[selectedPlan]
    }
    
    var selectedProduct: Product? {
        products[selectedPlan]
    }
    
    /// Calculate savings percentage for yearly vs monthly
    var yearlySavingsPercentage: Int? {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else { return nil }
        
        let monthlyAnnualCost = monthly.price * 12
        let yearlyCost = yearly.price
        
        guard monthlyAnnualCost > 0 else { return nil }
        
        let savings = (monthlyAnnualCost - yearlyCost) / monthlyAnnualCost * 100
        let savingsDouble = NSDecimalNumber(decimal: savings).doubleValue
        return Int(savingsDouble.rounded())
    }
    
    /// Monthly equivalent price for yearly plan
    var yearlyMonthlyEquivalent: Decimal? {
        guard let yearly = yearlyProduct else { return nil }
        return yearly.price / 12
    }
    
    // MARK: - Lifecycle
    
    init() {
        updatesTask = Task { await observeTransactions() }
        Task { await refreshEntitlements() }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    func loadProducts() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIds = SubscriptionPlan.allCases.map { $0.rawValue }
            let loadedProducts = try await Product.products(for: productIds)
            
            var productMap: [SubscriptionPlan: Product] = [:]
            for product in loadedProducts {
                if let plan = SubscriptionPlan(rawValue: product.id) {
                    productMap[plan] = product
                }
            }
            products = productMap
            return !products.isEmpty
        } catch {
            products = [:]
            return false
        }
    }
    
    func selectPlan(_ plan: SubscriptionPlan) {
        selectedPlan = plan
    }
    
    func purchase() async throws {
        try await purchase(plan: selectedPlan)
    }
    
    func purchase(plan: SubscriptionPlan) async throws {
        guard let product = products[plan] else {
            throw EntitlementError.productUnavailable
        }
        
        isLoading = true
        defer { isLoading = false }
        
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
        isLoading = true
        defer { isLoading = false }
        await refreshEntitlements()
    }
    
    // MARK: - Private Methods
    
    private func refreshEntitlements() async {
        var hasPro = false
        let validProductIds = Set(SubscriptionPlan.allCases.map { $0.rawValue })
        
        for await result in Transaction.currentEntitlements {
            if let transaction = try? verify(result),
               validProductIds.contains(transaction.productID) {
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
    
    // MARK: - Errors
    
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
