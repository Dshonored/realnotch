import SwiftUI

/// The idle notch: a plain black bar exactly the width of the physical notch —
/// nothing sticks out beside it.
struct CollapsedNotchView: View {
    /// Width of the physical notch.
    let notchWidth: CGFloat

    var body: some View {
        // A camera dot for synthetic notches, invisible behind the real cutout
        // on notched Macs.
        Circle()
            .fill(Color(hex: "#1A1A1CFF"))
            .frame(width: 6, height: 6)
            .overlay(Circle().strokeBorder(Color(hex: "#2B2B2EFF"), lineWidth: 1.2))
            .frame(width: notchWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
