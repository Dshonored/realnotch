import SwiftUI

/// The skin contract. Every field is optional in JSON — missing fields fall back
/// to `Theme.default` values, so skin authors override only what they want.
/// Documented for authors in docs/THEMES.md. Bump `schemaVersion` on breaking changes.
struct Theme: Codable, Hashable, Identifiable {
    var id: String { name }

    var schemaVersion: Int = 1
    var name: String = "Default"
    var author: String = "RealNotch"

    var colors: Colors = Colors()
    var shape: Shape = Shape()
    var typography: Typography = Typography()
    var material: Material = Material()
    var motion: Motion = Motion()

    struct Colors: Codable, Hashable {
        var background: String = "#0C0C0EE6"
        var surface: String = "#FFFFFF0D"
        var textPrimary: String = "#FFFFFFFF"
        var textSecondary: String = "#FFFFFF80"
        var accent: String = "#0A84FFFF"
        var stackChip: String = "#0A84FFFF"
        var border: String = "#FFFFFF17"
        var divider: String = "#FFFFFF14"
        var pin: String = "#FFCF3FFF"
        /// The "active / live / success" accent — status dot, Keep Awake, copy feedback.
        var success: String = "#30D158FF"
    }

    struct Shape: Codable, Hashable {
        var notchCornerRadius: Double = 16
        var panelCornerRadius: Double = 22
        var itemCornerRadius: Double = 11
    }

    struct Typography: Codable, Hashable {
        /// Font family name; empty means system font.
        var fontFamily: String = ""
        var itemSize: Double = 12
        var captionSize: Double = 10
        var titleSize: Double = 13
    }

    struct Material: Codable, Hashable {
        /// "none", "thin", or "regular"
        var blur: String = "regular"
        var backgroundOpacity: Double = 0.9
    }

    struct Motion: Codable, Hashable {
        var springResponse: Double = 0.35
        var springDamping: Double = 0.8
    }

    static let `default` = Theme()
}

// MARK: - Partial decoding (missing keys fall back to defaults)

extension Theme {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Theme.default
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? d.schemaVersion
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? d.name
        author = try c.decodeIfPresent(String.self, forKey: .author) ?? d.author
        colors = try c.decodeIfPresent(Colors.self, forKey: .colors) ?? d.colors
        shape = try c.decodeIfPresent(Shape.self, forKey: .shape) ?? d.shape
        typography = try c.decodeIfPresent(Typography.self, forKey: .typography) ?? d.typography
        material = try c.decodeIfPresent(Material.self, forKey: .material) ?? d.material
        motion = try c.decodeIfPresent(Motion.self, forKey: .motion) ?? d.motion
    }
}

private extension KeyedDecodingContainer {
    func or<T: Decodable>(_ type: T.Type, _ key: Key, _ fallback: T) -> T {
        (try? decodeIfPresent(type, forKey: key)).flatMap { $0 } ?? fallback
    }
}

extension Theme.Colors {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Theme.default.colors
        background = c.or(String.self, .background, d.background)
        surface = c.or(String.self, .surface, d.surface)
        textPrimary = c.or(String.self, .textPrimary, d.textPrimary)
        textSecondary = c.or(String.self, .textSecondary, d.textSecondary)
        accent = c.or(String.self, .accent, d.accent)
        stackChip = c.or(String.self, .stackChip, d.stackChip)
        border = c.or(String.self, .border, d.border)
        divider = c.or(String.self, .divider, d.divider)
        pin = c.or(String.self, .pin, d.pin)
        success = c.or(String.self, .success, d.success)
    }
}

extension Theme.Shape {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Theme.default.shape
        notchCornerRadius = c.or(Double.self, .notchCornerRadius, d.notchCornerRadius)
        panelCornerRadius = c.or(Double.self, .panelCornerRadius, d.panelCornerRadius)
        itemCornerRadius = c.or(Double.self, .itemCornerRadius, d.itemCornerRadius)
    }
}

extension Theme.Typography {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Theme.default.typography
        fontFamily = c.or(String.self, .fontFamily, d.fontFamily)
        itemSize = c.or(Double.self, .itemSize, d.itemSize)
        captionSize = c.or(Double.self, .captionSize, d.captionSize)
        titleSize = c.or(Double.self, .titleSize, d.titleSize)
    }
}

extension Theme.Material {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Theme.default.material
        blur = c.or(String.self, .blur, d.blur)
        backgroundOpacity = c.or(Double.self, .backgroundOpacity, d.backgroundOpacity)
    }
}

extension Theme.Motion {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Theme.default.motion
        springResponse = c.or(Double.self, .springResponse, d.springResponse)
        springDamping = c.or(Double.self, .springDamping, d.springDamping)
    }
}

// MARK: - SwiftUI conveniences

extension Theme {
    var spring: Animation { .spring(response: motion.springResponse, dampingFraction: motion.springDamping) }

    func font(_ size: Double, weight: Font.Weight = .regular) -> Font {
        typography.fontFamily.isEmpty
            ? .system(size: size, weight: weight)
            : .custom(typography.fontFamily, size: size)
    }
}

extension Color {
    /// Parses "#RRGGBB" or "#RRGGBBAA". Invalid strings yield black.
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&v), s.count == 6 || s.count == 8 else {
            self = .black
            return
        }
        if s.count == 6 { v = (v << 8) | 0xFF }
        self.init(
            .sRGB,
            red: Double((v >> 24) & 0xFF) / 255,
            green: Double((v >> 16) & 0xFF) / 255,
            blue: Double((v >> 8) & 0xFF) / 255,
            opacity: Double(v & 0xFF) / 255
        )
    }
}
