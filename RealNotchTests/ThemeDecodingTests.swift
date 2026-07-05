import XCTest
@testable import RealNotch

final class ThemeDecodingTests: XCTestCase {
    private func decode(_ json: String) throws -> Theme {
        try JSONDecoder().decode(Theme.self, from: Data(json.utf8))
    }

    func testEmptyJSONYieldsDefaultTheme() throws {
        let theme = try decode("{}")
        XCTAssertEqual(theme, .default)
    }

    func testPartialThemeMergesOntoDefaults() throws {
        let theme = try decode(#"""
        {
          "name": "Mine",
          "colors": { "accent": "#FF0000FF" },
          "shape": { "panelCornerRadius": 30 }
        }
        """#)
        XCTAssertEqual(theme.name, "Mine")
        XCTAssertEqual(theme.colors.accent, "#FF0000FF")
        XCTAssertEqual(theme.shape.panelCornerRadius, 30)
        // Everything not overridden stays default.
        XCTAssertEqual(theme.colors.background, Theme.default.colors.background)
        XCTAssertEqual(theme.shape.notchCornerRadius, Theme.default.shape.notchCornerRadius)
        XCTAssertEqual(theme.typography, Theme.default.typography)
        XCTAssertEqual(theme.motion, Theme.default.motion)
    }

    func testWrongTypeFieldFallsBackToDefault() throws {
        let theme = try decode(#"{ "name": "Odd", "shape": { "panelCornerRadius": "huge" } }"#)
        XCTAssertEqual(theme.shape.panelCornerRadius, Theme.default.shape.panelCornerRadius)
    }

    func testInvalidJSONThrows() {
        XCTAssertThrowsError(try decode("not json at all"))
    }

    func testFullRoundTrip() throws {
        var theme = Theme.default
        theme.name = "Round Trip"
        theme.colors.accent = "#12345678"
        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(Theme.self, from: data)
        XCTAssertEqual(decoded, theme)
    }
}
