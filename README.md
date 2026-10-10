# KelvinColor

Convert a colour temperature in kelvin to an sRGB colour, and to the per channel gain multipliers a display warmth filter needs. Pure Swift, no dependencies, works on macOS, iOS and Linux.

```swift
KelvinColor.rgb(kelvin: 2700)        // (r: 1.0, g: 0.65, b: 0.34)  incandescent
KelvinColor.whitePoint(kelvin: 3400) // gains relative to 6500 K, largest = 1
Color(kelvin: 1900)                  // SwiftUI candlelight
```

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/trysundown/KelvinColor.git", from: "1.0.0"),
],
targets: [
    .target(name: "YourTarget", dependencies: ["KelvinColor"]),
]
```

Or in Xcode choose File > Add Package Dependencies and paste the repository URL.

Requirements: Swift 5.9 or later. macOS 12 or later, iOS 15 or later. The core API also builds on Linux.

## Usage

### Colour of a temperature

```swift
import KelvinColor

let candle = KelvinColor.rgb(kelvin: 1900)
// candle.r == 1.0, candle.g ~ 0.52, candle.b == 0.0
```

`rgb(kelvin:)` returns gamma encoded sRGB with each channel in `0...1`. The brightest channel is always 1, so the result describes the hue of the light, not its brightness. Below about 6600 K red is pinned at 1; above it blue is pinned at 1.

Inputs are clamped to `1000...40000` K (`KelvinColor.validRange`). `NaN` is treated as 6500 K.

### Platform colours

```swift
let swiftUI = Color(kelvin: 3000)
let appKit = NSColor(kelvin: 3000)          // macOS
let uiKit = UIColor(kelvin: 3000, alpha: 1) // iOS
```

These are compiled only where the framework is available (`#if canImport`).

### Warmth filter multipliers

```swift
let gain = KelvinColor.whitePoint(kelvin: 3400)
// gain.r == 1.0, gain.g < 1.0, gain.b < gain.g
```

`whitePoint(kelvin:reference:)` divides the colour at the target temperature by the colour at a reference (6500 K by default) channel by channel, then scales the result so the largest multiplier is exactly 1. The filter only ever removes light, so nothing clips, and at the reference temperature the result is `(1, 1, 1)`.

To fade a filter in or out, blend toward neutral:

```swift
KelvinColor.whitePoint(kelvin: 2700, strength: 0.5)
```

To drive a display transfer table directly, ask for a linear ramp scaled by those gains:

```swift
let table = KelvinColor.gammaTable(kelvin: 2700, count: 256)
// table.red, table.green, table.blue: [Float], 0 up to each channel's gain
```

The arrays have the shape that APIs such as `CGSetDisplayTransferByTable` expect. Applying them to a display is left to your app.

## The formula

KelvinColor implements Tanner Helland's curve fit to blackbody colour data:

> Tanner Helland, "How to Convert Temperature (K) to RGB: Algorithm and Sample Code", 2012.
> https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html

With `t = kelvin / 100`, in 8-bit units then clamped to `0...255` and divided by 255:

| Channel | `t <= 66` | `t > 66` |
| --- | --- | --- |
| Red | `255` | `329.698727446 * (t - 60)^-0.1332047592` |
| Green | `99.4708025861 * ln(t) - 161.1195681661` | `288.1221695283 * (t - 60)^-0.0755148492` |
| Blue | `0` if `t <= 19`, else `138.5177312231 * ln(t - 10) - 305.0447927307` | `255` |

Blue uses `t >= 66` for the 255 branch, as in the original.

Helland fitted these curves to Mitchell Charity's blackbody colour table, which is computed with the CIE 1964 10 degree colour matching functions and sRGB primaries:
http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html

## Accuracy

- Helland reports R-squared values of 0.988 (red), 0.996 and 0.987 (green, low and high branches) and 0.998 (blue).
- Measured against all 391 rows of Charity's 10 degree table (1000 K to 40000 K in 100 K steps), the largest error in any channel is 11.9 / 255, for green at 1000 K. The mean of each row's largest channel error is 2.0 / 255, and 95 percent of rows are within 4.8 / 255.
- Between 2000 K and 40000 K no channel is off by more than 6 / 255.
- The piecewise fit has small steps at 6600 K: green drops by about 3 / 255 and blue rises by about 2.5 / 255. Red stays continuous. Red never increases and blue never decreases as temperature rises; the test suite checks both.
- This is a perceptual approximation for graphics and display work. It is not a colorimetric model: it ignores the observer's adaptation, the display's actual primaries and gamma, and luminance. For scientific work compute the Planckian locus from the CIE colour matching functions instead.

## Licence

MIT. See [LICENSE](LICENSE).

Maintained by the makers of Sundown, a Mac menu bar app that warms the display: https://trysundown.com
