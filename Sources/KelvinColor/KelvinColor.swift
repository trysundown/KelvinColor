// KelvinColor
// Copyright (c) 2026 Jack Richards. MIT License.
//
// Colour temperature to RGB using Tanner Helland's blackbody curve fit.
//
// Source: Tanner Helland, "How to Convert Temperature (K) to RGB: Algorithm
// and Sample Code", 2012.
// https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
//
// Helland fitted one curve per channel to Mitchell Charity's blackbody colour
// table (CIE 1964 10 degree colour matching functions, sRGB primaries):
// http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html
// The published R-squared values are 0.988 (red), 0.996 and 0.987 (green,
// low and high branches) and 0.998 (blue). The fit is stated as valid from
// 1000 K to 40000 K.
//
// Measured against all 391 rows of Charity's 10 degree table (1000 K to
// 40000 K in 100 K steps), the largest single channel error is 11.9 / 255
// (green at 1000 K) and the mean of the per-row maximum error is 2.0 / 255.

import Foundation

/// Converts a colour temperature in kelvin to an RGB colour.
///
/// All values are in `0...1` and are gamma encoded sRGB, ready to hand to
/// `Color(red:green:blue:)`, `NSColor(srgbRed:green:blue:alpha:)` and similar.
public enum KelvinColor {

    /// An RGB triple with every channel in `0...1`.
    public typealias RGB = (r: Double, g: Double, b: Double)

    /// The temperature range the approximation is fitted to. Inputs outside
    /// this range are clamped to it.
    public static let validRange: ClosedRange<Double> = 1000...40000

    /// The conventional daylight white point (D65 is close to 6500 K) used as
    /// the neutral reference by ``whitePoint(kelvin:reference:)``.
    public static let neutralKelvin: Double = 6500

    /// Clamps a temperature to ``validRange``. `NaN` maps to ``neutralKelvin``.
    public static func clamp(_ kelvin: Double) -> Double {
        guard !kelvin.isNaN else { return neutralKelvin }
        return min(max(kelvin, validRange.lowerBound), validRange.upperBound)
    }

    /// The sRGB colour of a blackbody radiator at `kelvin`.
    ///
    /// The brightest channel is always 1, so the result describes chromaticity
    /// only, not luminance. Below about 6600 K red is 1; above it blue is 1.
    ///
    /// - Parameter kelvin: Colour temperature. Clamped to ``validRange``.
    /// - Returns: Red, green and blue in `0...1`.
    public static func rgb(kelvin: Double) -> RGB {
        let t = clamp(kelvin) / 100

        let red: Double
        if t <= 66 {
            red = 255
        } else {
            red = 329.698727446 * pow(t - 60, -0.1332047592)
        }

        let green: Double
        if t <= 66 {
            green = 99.4708025861 * log(t) - 161.1195681661
        } else {
            green = 288.1221695283 * pow(t - 60, -0.0755148492)
        }

        let blue: Double
        if t >= 66 {
            blue = 255
        } else if t <= 19 {
            blue = 0
        } else {
            blue = 138.5177312231 * log(t - 10) - 305.0447927307
        }

        return (unit(red), unit(green), unit(blue))
    }

    /// Per channel gain multipliers that shift a display from `reference` to
    /// `kelvin`, for use as a warmth (or coolness) filter.
    ///
    /// The colour at `kelvin` is divided channel by channel by the colour at
    /// `reference`, then scaled so the largest multiplier is exactly 1. That
    /// keeps every channel at or below its original level, so the filter only
    /// ever removes light and never clips. At `kelvin == reference` the result
    /// is `(1, 1, 1)`.
    ///
    /// Multiply these into a linear gamma ramp (see
    /// ``gammaTable(kelvin:reference:count:)``) or into each channel of a pixel.
    ///
    /// - Parameters:
    ///   - kelvin: Target colour temperature. Clamped to ``validRange``.
    ///   - reference: The temperature treated as neutral. Defaults to 6500 K.
    /// - Returns: Red, green and blue multipliers in `0...1`.
    public static func whitePoint(kelvin: Double, reference: Double = neutralKelvin) -> RGB {
        let target = rgb(kelvin: kelvin)
        let base = rgb(kelvin: reference)
        let r = ratio(target.r, base.r)
        let g = ratio(target.g, base.g)
        let b = ratio(target.b, base.b)
        let peak = max(r, g, b)
        guard peak > 0 else { return (1, 1, 1) }
        return (r / peak, g / peak, b / peak)
    }

    /// Blends ``whitePoint(kelvin:reference:)`` toward neutral.
    ///
    /// - Parameters:
    ///   - kelvin: Target colour temperature.
    ///   - strength: `0` gives `(1, 1, 1)`, `1` gives the full white point.
    ///     Clamped to `0...1`.
    ///   - reference: The temperature treated as neutral.
    public static func whitePoint(kelvin: Double, strength: Double, reference: Double = neutralKelvin) -> RGB {
        let s = strength.isNaN ? 0 : min(max(strength, 0), 1)
        let full = whitePoint(kelvin: kelvin, reference: reference)
        return (1 + (full.r - 1) * s, 1 + (full.g - 1) * s, 1 + (full.b - 1) * s)
    }

    /// A linear gamma ramp scaled by ``whitePoint(kelvin:reference:)``.
    ///
    /// Each array has `count` entries running from 0 to the channel's
    /// multiplier. The shape matches what display transfer table APIs expect,
    /// for example `CGSetDisplayTransferByTable` on macOS.
    ///
    /// - Parameters:
    ///   - kelvin: Target colour temperature.
    ///   - reference: The temperature treated as neutral.
    ///   - count: Number of entries per channel. Values below 2 are raised to 2.
    public static func gammaTable(
        kelvin: Double,
        reference: Double = neutralKelvin,
        count: Int = 256
    ) -> (red: [Float], green: [Float], blue: [Float]) {
        let n = max(count, 2)
        let gain = whitePoint(kelvin: kelvin, reference: reference)
        var red = [Float](repeating: 0, count: n)
        var green = [Float](repeating: 0, count: n)
        var blue = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let x = Double(i) / Double(n - 1)
            red[i] = Float(x * gain.r)
            green[i] = Float(x * gain.g)
            blue[i] = Float(x * gain.b)
        }
        return (red, green, blue)
    }

    // MARK: - Private

    private static func unit(_ value8: Double) -> Double {
        min(max(value8, 0), 255) / 255
    }

    private static func ratio(_ a: Double, _ b: Double) -> Double {
        // The reference can only have a zero channel below 1900 K (blue).
        // Treat that channel as passing through unchanged.
        b > 0 ? a / b : 1
    }
}
