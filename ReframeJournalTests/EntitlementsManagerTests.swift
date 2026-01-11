import XCTest
import StoreKit
@testable import ReframeJournal

final class EntitlementsManagerTests: XCTestCase {
    
    @MainActor
    func testSubscriptionPlanRawValues() {
        XCTAssertEqual(SubscriptionPlan.monthly.rawValue, "reframejournal.pro.monthly")
        XCTAssertEqual(SubscriptionPlan.yearly.rawValue, "reframejournal.pro.yearly")
    }
    
    @MainActor
    func testSubscriptionPlanDisplayNames() {
        XCTAssertEqual(SubscriptionPlan.monthly.displayName, "Monthly")
        XCTAssertEqual(SubscriptionPlan.yearly.displayName, "Yearly")
    }
    
    @MainActor
    func testSubscriptionPlanAllCases() {
        let allCases = SubscriptionPlan.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.monthly))
        XCTAssertTrue(allCases.contains(.yearly))
    }
    
    @MainActor
    func testSubscriptionPlanInitFromRawValue() {
        XCTAssertEqual(SubscriptionPlan(rawValue: "reframejournal.pro.monthly"), .monthly)
        XCTAssertEqual(SubscriptionPlan(rawValue: "reframejournal.pro.yearly"), .yearly)
        XCTAssertNil(SubscriptionPlan(rawValue: "invalid"))
    }
    
    @MainActor
    func testEntitlementErrorDescriptions() {
        let productUnavailable = EntitlementsManager.EntitlementError.productUnavailable
        XCTAssertNotNil(productUnavailable.errorDescription)
        XCTAssertTrue(productUnavailable.errorDescription?.contains("unavailable") ?? false)
        
        let failedVerification = EntitlementsManager.EntitlementError.failedVerification
        XCTAssertNotNil(failedVerification.errorDescription)
        XCTAssertTrue(failedVerification.errorDescription?.contains("verified") ?? false)
    }
    
    @MainActor
    func testEntitlementsManagerInitialState() {
        let manager = EntitlementsManager()
        
        XCTAssertFalse(manager.isPro)
        XCTAssertTrue(manager.products.isEmpty)
        XCTAssertEqual(manager.selectedPlan, .yearly)
        XCTAssertFalse(manager.isLoading)
    }
    
    @MainActor
    func testSelectPlan() {
        let manager = EntitlementsManager()
        
        manager.selectPlan(.monthly)
        XCTAssertEqual(manager.selectedPlan, .monthly)
        
        manager.selectPlan(.yearly)
        XCTAssertEqual(manager.selectedPlan, .yearly)
    }
    
    @MainActor
    func testSelectedProductIsNilInitially() {
        let manager = EntitlementsManager()
        XCTAssertNil(manager.selectedProduct)
        XCTAssertNil(manager.monthlyProduct)
        XCTAssertNil(manager.yearlyProduct)
        XCTAssertNil(manager.proProduct) // Backward compatibility
    }
    
    // Note: Testing loadProducts, purchase, and restore would require mocking StoreKit,
    // which is complex and may not be practical for unit tests. These methods are
    // better tested via integration tests or UI tests.
}
