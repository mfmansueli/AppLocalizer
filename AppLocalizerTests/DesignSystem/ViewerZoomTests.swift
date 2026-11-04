//
//  ViewerZoomTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The full-size viewer's zoom: a pinch keeps the point between the
/// fingers in place, it stays between fit and 8×, a pan never shows past
/// the edges, and a double-click goes to 2× and back.
@Suite("Viewer zoom")
struct ViewerZoomTests {
    private let size = CGSize(width: 400, height: 800)

    @Test func fitIsNotZoomedAndSaysOneHundredPercent() {
        #expect(!ViewerZoom.fit.isZoomed)
        #expect(ViewerZoom.fit.percentTitle == "100%")
    }

    @Test func aPinchKeepsThePointUnderTheFingersInPlace() {
        let anchor = CGPoint(x: 100, y: -200)
        let zoom = ViewerZoom.fit.pinched(by: 2, around: anchor, in: size)
        #expect(zoom.scale == 2)
        #expect(zoom.offset == CGSize(width: -100, height: 200))
        // The content point shown under the fingers: (anchor − offset) ÷ scale.
        #expect((anchor.x - zoom.offset.width) / zoom.scale == anchor.x)
        #expect((anchor.y - zoom.offset.height) / zoom.scale == anchor.y)
        #expect(zoom.percentTitle == "200%")
    }

    @Test func aPinchStaysBetweenFitAndEightTimes() {
        #expect(ViewerZoom.fit.pinched(by: 100, around: .zero, in: size).scale == ViewerZoom.maximumScale)
        #expect(ViewerZoom.fit.pinched(by: 0.2, around: CGPoint(x: 50, y: 50), in: size) == .fit)
    }

    @Test func pinchingBackOutComesBackCentred() {
        let zoomed = ViewerZoom(scale: 3, offset: CGSize(width: 120, height: -300))
        #expect(zoomed.pinched(by: 1 / 3, around: CGPoint(x: 80, y: 10), in: size) == .fit)
    }

    @Test func aPanStopsAtTheEdges() {
        let zoomed = ViewerZoom(scale: 2, offset: .zero)
        let panned = zoomed.panned(by: CGSize(width: 1000, height: -1000), in: size)
        // At 2× the content is one frame bigger: half a frame each way.
        #expect(panned.offset == CGSize(width: 200, height: -400))
        #expect(zoomed.panned(by: CGSize(width: 30, height: 40), in: size).offset == CGSize(width: 30, height: 40))
    }

    @Test func atFitAPanDoesNothing() {
        #expect(ViewerZoom.fit.panned(by: CGSize(width: 50, height: 50), in: size) == .fit)
    }

    @Test func aPinchInACornerStaysInsideTheContent() {
        let zoom = ViewerZoom.fit.pinched(by: 2, around: CGPoint(x: 300, y: 600), in: size)
        #expect(zoom.offset == CGSize(width: -200, height: -400))
    }

    @Test func aDoubleClickZoomsToTwiceAroundItThenBackToFit() {
        let zoomed = ViewerZoom.fit.toggled(around: CGPoint(x: 50, y: 0), in: size)
        #expect(zoomed.scale == ViewerZoom.doubleClickScale)
        #expect(zoomed.offset == CGSize(width: -50, height: 0))
        #expect(zoomed.toggled(around: .zero, in: size) == .fit)
    }
}
