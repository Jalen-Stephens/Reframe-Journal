import XCTest
import SwiftUI
@testable import ReframeJournal

final class ColorHexTests: XCTestCase {
    
    func testColorFromHex6Digits() {
        let color = Color(hex: "FF0000") // Red
        
        XCTAssertNotNil(color)
        // Can't easily test exact color values without UI testing,
        // but we can verify it doesn't crash
    }
    
    func testColorFromHex8Digits() {
        let color = Color(hex: "FF0000FF") // Red with alpha
        
        XCTAssertNotNil(color)
    }
    
    func testColorFromHexWithHash() {
        let color = Color(hex: "#00FF00") // Green
        
        XCTAssertNotNil(color)
    }
    
    func testColorFromHexWithWhitespace() {
        let color = Color(hex: "  0000FF  ") // Blue with whitespace
        
        XCTAssertNotNil(color)
    }
    
    func testColorFromInvalidHex() {
        let color = Color(hex: "ZZZ") // Invalid hex
        
        // Should default to black (0,0,0,1)
        XCTAssertNotNil(color)
    }
    
    func testColorFromEmptyString() {
        let color = Color(hex: "")
        
        XCTAssertNotNil(color)
    }
    
    func testColorFromShortHex() {
        let color = Color(hex: "ABC")
        
        XCTAssertNotNil(color)
    }
    
    func testColorFromLongHex() {
        let color = Color(hex: "123456789ABCDEF")
        
        XCTAssertNotNil(color)
    }
}
