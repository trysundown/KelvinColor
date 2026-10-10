# Changelog

All notable changes to this project are documented here. The format follows Keep a Changelog and the project uses Semantic Versioning.

## [1.0.0] - 2026-10-10

### Added

- `KelvinColor.rgb(kelvin:)`: colour temperature to sRGB using Tanner Helland's blackbody fit, clamped to 1000 K to 40000 K.
- `KelvinColor.whitePoint(kelvin:reference:)` and `whitePoint(kelvin:strength:reference:)`: per channel gain multipliers for a display warmth filter.
- `KelvinColor.gammaTable(kelvin:reference:count:)`: linear gamma ramps scaled by the white point.
- `Color(kelvin:opacity:)`, `NSColor(kelvin:alpha:)` and `UIColor(kelvin:alpha:)` conveniences.
- Tests against Mitchell Charity's blackbody reference table.
