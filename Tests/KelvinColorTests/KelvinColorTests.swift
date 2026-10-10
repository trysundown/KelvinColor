import XCTest
@testable import KelvinColor

final class KelvinColorTests: XCTestCase {

    // Mitchell Charity's blackbody table, CIE 1964 10 degree CMFs, 8-bit sRGB.
    // http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html
    private let charity: [(k: Double, r: Double, g: Double, b: Double)] = [
        (1000, 255, 56, 0),
        (1200, 255, 83, 0),
        (1500, 255, 109, 0),
        (1900, 255, 131, 0),
        (2700, 255, 169, 87),
        (3000, 255, 180, 107),
        (4000, 255, 209, 163),
        (5000, 255, 228, 206),
        (6500, 255, 249, 253),
        (8000, 227, 233, 255),
        (10000, 204, 219, 255),
        (20000, 168, 197, 255),
        (40000, 155, 188, 255),
    ]

    func testMatchesBlackbodyReferenceTable() {
        for row in charity {
            let c = KelvinColor.rgb(kelvin: row.k)
            // The fit is loosest at the very bottom of the range.
            let tolerance = (row.k < 1200 ? 12.0 : 6.0) / 255
            XCTAssertEqual(c.r, row.r / 255, accuracy: tolerance, "red at \(row.k) K")
            XCTAssertEqual(c.g, row.g / 255, accuracy: tolerance, "green at \(row.k) K")
            XCTAssertEqual(c.b, row.b / 255, accuracy: tolerance, "blue at \(row.k) K")
        }
    }

    func test6500KIsCloseToWhite() {
        let c = KelvinColor.rgb(kelvin: 6500)
        XCTAssertEqual(c.r, 1, accuracy: 0.001)
        XCTAssertGreaterThan(c.g, 0.98)
        XCTAssertGreaterThan(c.b, 0.97)
    }

    func test1900KCandleIsOrangeWithNoBlue() {
        let c = KelvinColor.rgb(kelvin: 1900)
        XCTAssertEqual(c.r, 1, accuracy: 0.001)
        XCTAssertEqual(c.g, 131.0 / 255, accuracy: 2.0 / 255)
        XCTAssertEqual(c.b, 0, accuracy: 0.001)
    }

    func test1200KIsDeepWarm() {
        let c = KelvinColor.rgb(kelvin: 1200)
        XCTAssertEqual(c.r, 1, accuracy: 0.001)
        XCTAssertLessThan(c.g, 0.36)
        XCTAssertEqual(c.b, 0, accuracy: 0.001)
    }

    func test500KClampsToTheWarmEnd() {
        let below = KelvinColor.rgb(kelvin: 500)
        let floor = KelvinColor.rgb(kelvin: 1000)
        XCTAssertEqual(below.r, floor.r)
        XCTAssertEqual(below.g, floor.g)
        XCTAssertEqual(below.b, floor.b)
        XCTAssertLessThan(below.g, 0.3)
        XCTAssertEqual(below.b, 0)
    }

    func testClampingAboveRangeAndSpecialValues() {
        let top = KelvinColor.rgb(kelvin: 40000)
        for k in [40001.0, 100_000, .infinity] {
            let c = KelvinColor.rgb(kelvin: k)
            XCTAssertEqual(c.r, top.r)
            XCTAssertEqual(c.g, top.g)
            XCTAssertEqual(c.b, top.b)
        }
        XCTAssertEqual(KelvinColor.clamp(-.infinity), 1000)
        XCTAssertEqual(KelvinColor.clamp(-5), 1000)
        XCTAssertEqual(KelvinColor.clamp(.nan), 6500)
    }

    func testChannelsStayInUnitRange() {
        var k = 0.0
        while k <= 45000 {
            let c = KelvinColor.rgb(kelvin: k)
            for v in [c.r, c.g, c.b] {
                XCTAssertGreaterThanOrEqual(v, 0)
                XCTAssertLessThanOrEqual(v, 1)
            }
            k += 50
        }
    }

    func testRedNeverIncreasesAndBlueNeverDecreasesWithTemperature() {
        var previous = KelvinColor.rgb(kelvin: 1000)
        var k = 1010.0
        while k <= 40000 {
            let c = KelvinColor.rgb(kelvin: k)
            XCTAssertLessThanOrEqual(c.r, previous.r + 1e-12, "red rose at \(k) K")
            XCTAssertGreaterThanOrEqual(c.b, previous.b - 1e-12, "blue fell at \(k) K")
            previous = c
            k += 10
        }
    }

    func testWhitePointIsNeutralAtReference() {
        let w = KelvinColor.whitePoint(kelvin: 6500)
        XCTAssertEqual(w.r, 1, accuracy: 1e-12)
        XCTAssertEqual(w.g, 1, accuracy: 1e-12)
        XCTAssertEqual(w.b, 1, accuracy: 1e-12)
    }

    func testWarmWhitePointCutsBlueMoreThanGreen() {
        let w = KelvinColor.whitePoint(kelvin: 3400)
        XCTAssertEqual(w.r, 1, accuracy: 1e-12)
        XCTAssertLessThan(w.g, 1)
        XCTAssertLessThan(w.b, w.g)
        XCTAssertGreaterThan(w.b, 0)
    }

    func testCoolWhitePointCutsRed() {
        let w = KelvinColor.whitePoint(kelvin: 10000)
        XCTAssertEqual(w.b, 1, accuracy: 1e-12)
        XCTAssertLessThan(w.r, w.g)
    }

    func testWhitePointNeverExceedsOne() {
        var k = 1000.0
        while k <= 40000 {
            let w = KelvinColor.whitePoint(kelvin: k)
            XCTAssertLessThanOrEqual(max(w.r, w.g, w.b), 1 + 1e-12)
            XCTAssertEqual(max(w.r, w.g, w.b), 1, accuracy: 1e-12)
            XCTAssertGreaterThanOrEqual(min(w.r, w.g, w.b), 0)
            k += 100
        }
    }

    func testWhitePointWithLowReferenceHandlesZeroBlue() {
        let w = KelvinColor.whitePoint(kelvin: 1200, reference: 1500)
        XCTAssertFalse(w.r.isNaN || w.g.isNaN || w.b.isNaN)
        XCTAssertLessThanOrEqual(max(w.r, w.g, w.b), 1 + 1e-12)
    }

    func testWhitePointStrengthBlendsTowardNeutral() {
        let none = KelvinColor.whitePoint(kelvin: 2000, strength: 0)
        XCTAssertEqual(none.r, 1); XCTAssertEqual(none.g, 1); XCTAssertEqual(none.b, 1)

        let full = KelvinColor.whitePoint(kelvin: 2000)
        let all = KelvinColor.whitePoint(kelvin: 2000, strength: 1)
        XCTAssertEqual(all.g, full.g, accuracy: 1e-12)
        XCTAssertEqual(all.b, full.b, accuracy: 1e-12)

        let half = KelvinColor.whitePoint(kelvin: 2000, strength: 0.5)
        XCTAssertEqual(half.g, (1 + full.g) / 2, accuracy: 1e-12)
        XCTAssertEqual(half.b, (1 + full.b) / 2, accuracy: 1e-12)
    }

    func testGammaTableIsLinearAndScaled() {
        let table = KelvinColor.gammaTable(kelvin: 2700, count: 256)
        let w = KelvinColor.whitePoint(kelvin: 2700)
        XCTAssertEqual(table.red.count, 256)
        XCTAssertEqual(table.green.count, 256)
        XCTAssertEqual(table.blue.count, 256)
        XCTAssertEqual(table.red.first, 0)
        XCTAssertEqual(Double(table.red.last!), w.r, accuracy: 1e-6)
        XCTAssertEqual(Double(table.green.last!), w.g, accuracy: 1e-6)
        XCTAssertEqual(Double(table.blue.last!), w.b, accuracy: 1e-6)
        XCTAssertEqual(Double(table.green[128]), w.g * 128 / 255, accuracy: 1e-6)
        XCTAssertEqual(KelvinColor.gammaTable(kelvin: 2700, count: 0).red.count, 2)
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    func testNSColorConvenience() {
        let c = NSColor(kelvin: 1900)
        XCTAssertEqual(c.redComponent, 1, accuracy: 0.001)
        XCTAssertEqual(c.blueComponent, 0, accuracy: 0.001)
    }
    #endif

    #if canImport(UIKit)
    func testUIColorConvenience() {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(kelvin: 1900).getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 1, accuracy: 0.001)
        XCTAssertEqual(b, 0, accuracy: 0.001)
    }
    #endif
}
