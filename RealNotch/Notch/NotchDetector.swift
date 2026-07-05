import AppKit

enum NotchDetector {
    struct Geometry {
        let screen: NSScreen
        let notchWidth: CGFloat
        let notchHeight: CGFloat
    }

    /// Prefers a screen with a real notch; falls back to the main screen with a
    /// phantom notch so the app works on external displays and older Macs.
    static func detect() -> Geometry? {
        let screens = NSScreen.screens
        if let notched = screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            let width: CGFloat
            if let left = notched.auxiliaryTopLeftArea, let right = notched.auxiliaryTopRightArea {
                width = right.minX - left.maxX
            } else {
                width = 200
            }
            return Geometry(screen: notched, notchWidth: width, notchHeight: notched.safeAreaInsets.top)
        }
        guard let main = NSScreen.main ?? screens.first else { return nil }
        // No hardware notch: synthesize one at the menu-bar height, like boring.notch
        // and NotchDrop do, so the pill lines up with the menu bar on any display.
        let menuBarHeight = main.frame.maxY - main.visibleFrame.maxY
        return Geometry(screen: main, notchWidth: 185, notchHeight: max(menuBarHeight, 24))
    }
}
