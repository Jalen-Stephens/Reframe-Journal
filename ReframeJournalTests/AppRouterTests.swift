import XCTest
@testable import ReframeJournal

@MainActor
final class AppRouterTests: XCTestCase {
    
    func testInitialState() {
        let router = AppRouter()
        
        XCTAssertTrue(router.path.isEmpty)
    }
    
    func testPush() {
        let router = AppRouter()
        
        router.push(.allEntries)
        XCTAssertEqual(router.path.count, 1)
        XCTAssertEqual(router.path.first, .allEntries)
    }
    
    func testPushMultiple() {
        let router = AppRouter()
        
        router.push(.allEntries)
        router.push(.entryDetail(id: "test_id"))
        router.push(.settings)
        
        XCTAssertEqual(router.path.count, 3)
        XCTAssertEqual(router.path[0], .allEntries)
        XCTAssertEqual(router.path[1], .entryDetail(id: "test_id"))
        XCTAssertEqual(router.path[2], .settings)
    }
    
    func testPop() {
        let router = AppRouter()
        
        router.push(.allEntries)
        router.push(.settings)
        
        router.pop()
        
        XCTAssertEqual(router.path.count, 1)
        XCTAssertEqual(router.path.first, .allEntries)
    }
    
    func testPopWhenEmpty() {
        let router = AppRouter()
        
        router.pop() // Should not crash
        
        XCTAssertTrue(router.path.isEmpty)
    }
    
    func testPopToRoot() {
        let router = AppRouter()
        
        router.push(.allEntries)
        router.push(.entryDetail(id: "test_id"))
        router.push(.settings)
        
        router.popToRoot()
        
        XCTAssertTrue(router.path.isEmpty)
    }
    
    func testPopToRootWhenEmpty() {
        let router = AppRouter()
        
        router.popToRoot() // Should not crash
        
        XCTAssertTrue(router.path.isEmpty)
    }
    
    func testRouteEquality() {
        let route1 = Route.entryDetail(id: "test_id")
        let route2 = Route.entryDetail(id: "test_id")
        let route3 = Route.entryDetail(id: "different_id")
        
        XCTAssertEqual(route1, route2)
        XCTAssertNotEqual(route1, route3)
    }
    
    func testAIReframeActionEquality() {
        let action1 = AIReframeAction.view
        let action2 = AIReframeAction.view
        let action3 = AIReframeAction.generate
        
        XCTAssertEqual(action1, action2)
        XCTAssertNotEqual(action1, action3)
    }
    
    func testRouteHashable() {
        var set = Set<Route>()
        set.insert(.allEntries)
        set.insert(.settings)
        set.insert(.allEntries) // Duplicate
        
        XCTAssertEqual(set.count, 2)
    }
}
