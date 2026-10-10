// KelvinColor
// Copyright (c) 2026 Jack Richards. MIT License.

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Color {
    /// The sRGB colour of a blackbody radiator at `kelvin`.
    ///
    /// - Parameters:
    ///   - kelvin: Colour temperature, clamped to `1000...40000`.
    ///   - opacity: Alpha in `0...1`.
    public init(kelvin: Double, opacity: Double = 1) {
        let c = KelvinColor.rgb(kelvin: kelvin)
        self.init(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: opacity)
    }
}
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSColor {
    /// The sRGB colour of a blackbody radiator at `kelvin`.
    ///
    /// - Parameters:
    ///   - kelvin: Colour temperature, clamped to `1000...40000`.
    ///   - alpha: Alpha in `0...1`.
    public convenience init(kelvin: Double, alpha: CGFloat = 1) {
        let c = KelvinColor.rgb(kelvin: kelvin)
        self.init(srgbRed: CGFloat(c.r), green: CGFloat(c.g), blue: CGFloat(c.b), alpha: alpha)
    }
}
#endif

#if canImport(UIKit)
import UIKit

extension UIColor {
    /// The sRGB colour of a blackbody radiator at `kelvin`.
    ///
    /// - Parameters:
    ///   - kelvin: Colour temperature, clamped to `1000...40000`.
    ///   - alpha: Alpha in `0...1`.
    public convenience init(kelvin: Double, alpha: CGFloat = 1) {
        let c = KelvinColor.rgb(kelvin: kelvin)
        self.init(red: CGFloat(c.r), green: CGFloat(c.g), blue: CGFloat(c.b), alpha: alpha)
    }
}
#endif
