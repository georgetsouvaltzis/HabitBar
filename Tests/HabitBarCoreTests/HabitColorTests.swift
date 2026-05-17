import XCTest
@testable import HabitBarCore

final class HabitColorTests: XCTestCase {
    func testLightPastelIsDarkenedForLightModeTextContrast() {
        let pastel = HabitColor(red: 0.95, green: 0.95, blue: 0.40)
        let adjusted = pastel.contrastAdjusted(forDarkMode: false)

        XCTAssertLessThan(adjusted.red, pastel.red)
        XCTAssertLessThan(adjusted.green, pastel.green)
    }

    func testDarkColorIsLightenedForDarkModeTextContrast() {
        let deep = HabitColor(red: 0.05, green: 0.20, blue: 0.10)
        let adjusted = deep.contrastAdjusted(forDarkMode: true)

        XCTAssertGreaterThan(adjusted.red, deep.red)
        XCTAssertGreaterThan(adjusted.green, deep.green)
    }
}

