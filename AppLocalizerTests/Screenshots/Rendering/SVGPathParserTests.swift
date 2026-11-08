//
//  SVGPathParserTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import SwiftUI
import Testing
@testable import AppLocalizer

/// SVG path data the way the design writes its shapes and props: every
/// command, absolute and relative, numbers run together, arcs as cubics,
/// and data it can't read ending the path there.
@Suite("SVGPathParser")
struct SVGPathParserTests {
    /// The path's own bounds, not its control points'.
    private func bounds(_ data: String) -> CGRect {
        SVGPathParser.path(data).cgPath.boundingBoxOfPath
    }

    private func end(_ data: String) -> CGPoint? {
        SVGPathParser.path(data).currentPoint
    }

    private func isClose(_ lhs: CGRect, _ rhs: CGRect, within tolerance: CGFloat = 0.05) -> Bool {
        abs(lhs.minX - rhs.minX) < tolerance && abs(lhs.minY - rhs.minY) < tolerance
            && abs(lhs.width - rhs.width) < tolerance && abs(lhs.height - rhs.height) < tolerance
    }

    @Test func absoluteLinesAndClose() {
        #expect(bounds("M0 0 L10 0 L10 10 Z") == CGRect(x: 0, y: 0, width: 10, height: 10))
    }

    @Test func relativeCommandsMoveFromTheCurrentPoint() {
        #expect(bounds("m5 5 h10 v10 h-10 z") == CGRect(x: 5, y: 5, width: 10, height: 10))
        #expect(end("M5 5 l3 4 l1 1") == CGPoint(x: 9, y: 10))
    }

    @Test func pairsAfterAMoveAreLines() {
        #expect(bounds("M0 0 10 0 10 10") == CGRect(x: 0, y: 0, width: 10, height: 10))
        #expect(end("m1 1 2 2 2 2") == CGPoint(x: 5, y: 5))
    }

    @Test func numbersRunTogetherAndExponentsRead() {
        #expect(end("M0.5.5h1") == CGPoint(x: 1.5, y: 0.5))
        #expect(end("M0,0L1e1,0") == CGPoint(x: 10, y: 0))
        #expect(end("M10-5l-2-3") == CGPoint(x: 8, y: -8))
        #expect(end("M0 0H8V-2.5") == CGPoint(x: 8, y: -2.5))
    }

    @Test func anArcIsHalfACircle() {
        // From the left of a circle of radius 10 to its right, over the top.
        #expect(isClose(bounds("M0 10 A10 10 0 0 1 20 10"), CGRect(x: 0, y: 0, width: 20, height: 10)))
        // The other sweep goes under.
        #expect(isClose(bounds("M0 10 A10 10 0 0 0 20 10"), CGRect(x: 0, y: 10, width: 20, height: 10)))
        #expect(end("M0 10 a10 10 0 0 1 20 0") == CGPoint(x: 20, y: 10))
    }

    @Test func anArcTooSmallToReachGrowsUntilItDoes() {
        #expect(isClose(bounds("M0 0 A1 1 0 0 1 20 0"), CGRect(x: 0, y: -10, width: 20, height: 10)))
    }

    @Test func aLargeArcGoesTheLongWayRound() {
        // Three quarters of a circle of radius 10 centered at (10, 10).
        let large = bounds("M10 0 A10 10 0 1 1 0 10")
        #expect(isClose(large, CGRect(x: 0, y: 0, width: 20, height: 20)))
        let small = bounds("M10 0 A10 10 0 0 0 0 10")
        #expect(small.width < 11)
    }

    @Test func smoothCurvesReflectTheLastControlPoint() {
        // Q peaks at 5; T reflects its control point and dips to -5.
        let quads = bounds("M0 0 Q10 10 20 0 T40 0")
        #expect(isClose(quads, CGRect(x: 0, y: -5, width: 40, height: 10)))
        #expect(end("M0 0 q10 10 20 0 t20 0") == CGPoint(x: 40, y: 0))
        // C rises to 7.5; S mirrors it below.
        let cubics = bounds("M0 0 C0 10 10 10 10 0 S20 -10 20 0")
        #expect(isClose(cubics, CGRect(x: 0, y: -7.5, width: 20, height: 15)))
        #expect(end("M0 0 c0 10 10 10 10 0 s10 -10 10 0") == CGPoint(x: 20, y: 0))
    }

    @Test func dataItCantReadEndsThePathThere() {
        #expect(bounds("M0 0 L10 0 L") == CGRect(x: 0, y: 0, width: 10, height: 0))
        #expect(end("M0 0 L10 0 X5 5 L20 20") == CGPoint(x: 10, y: 0))
        #expect(SVGPathParser.path("").isEmpty)
    }

    @Test func shapesStillParseThroughTheParser() {
        let path = DecorationShapePath.parse("M0 0 L100 0 L100 50 Z")
        #expect(path.cgPath.boundingBoxOfPath == CGRect(x: 0, y: 0, width: 100, height: 50))
    }
}
