//
//  AppPreviewSettlerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// MB Admin's App Preview opened on an empty list still loading: a moment
/// now starts once its screen has filled in.
@MainActor
@Suite("App Preview settler")
struct AppPreviewSettlerTests {
    private static let spec = AppPreviewSpec(displayType: .iPhone, pixelSize: PixelSize(width: 886, height: 1920))

    @Test func itStartsOnceTheScreenHasFilledIn() {
        #expect(AppPreviewSettler.offset(blankShares: [0.5, 0.45, 0.1, 0.08, 0.1]) == 0.5)
        #expect(AppPreviewSettler.offset(blankShares: [0.6, nil, 0.2]) == 0.5)
    }

    @Test func aScreenThatOpensFilledInOrCantBeReadStays() {
        #expect(AppPreviewSettler.offset(blankShares: [0.1, 0.1, 0.05]) == 0, "Less than 0.15 blanker")
        #expect(AppPreviewSettler.offset(blankShares: [nil, 0.1]) == 0)
        #expect(AppPreviewSettler.offset(blankShares: []) == 0)
        #expect(AppPreviewSettler.offset(blankShares: [1, 1, 1]) == 0, "A flat screen throughout")
    }

    @Test func itKeepsItsLengthWhenTheMomentHasRoom() {
        let segment = AppPreviewSegment(screenID: "today", start: 1, duration: 6)
        let roomy = AppPreviewSettler.moved(segment, by: 0.5, momentEnd: 10, spec: Self.spec)
        #expect(roomy.start == 1.5)
        #expect(roomy.duration == 6)

        let tight = AppPreviewSettler.moved(segment, by: 0.5, momentEnd: 7.2, spec: Self.spec)
        #expect(tight.start == 1.5)
        #expect(tight.duration == 5.5, "It ends where it did")
        #expect(AppPreviewSettler.moved(segment, by: 0.5, momentEnd: nil, spec: Self.spec).end == 7)
    }

    /// A second of a blank screen, then a busy one, at 10 frames a second.
    private nonisolated static func writeLoadingRecording(to url: URL) async throws {
        var spec = AppPreviewSpec(displayType: .iPhone, pixelSize: PixelSize(width: 240, height: 520))
        spec.framesPerSecond = 10
        let writer = try AppPreviewWriter(output: url, spec: spec, bitRate: 2_000_000)
        for index in 0..<40 {
            let isBusy = Double(index) / 10 >= 1
            try await writer.appendFrame { context in
                context.setFillColor(CGColor(gray: 1, alpha: 1))
                context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))
                guard isBusy else { return }
                context.setFillColor(CGColor(gray: 0, alpha: 1))
                for y in stride(from: 0, to: context.height, by: 8) {
                    for x in stride(from: (y / 8).isMultiple(of: 2) ? 0 : 4, to: context.width, by: 8) {
                        context.fill(CGRect(x: x, y: y, width: 4, height: 4))
                    }
                }
            }
        }
        try await writer.finish()
    }

    @Test func aLoadingOpeningIsSkippedInARecording() async throws {
        let url = AppPreviewTestRecording.temporaryURL("loading.mov")
        defer { try? FileManager.default.removeItem(at: url) }
        try await Self.writeLoadingRecording(to: url)

        let segment = AppPreviewSegment(screenID: "today", start: 0.3, duration: 3)
        let settled = await AppPreviewSettler.settled([segment], recording: url, momentEnds: ["today": 3.9], spec: Self.spec)
        #expect(settled.count == 1)
        // 0.75 s in, rounded up to whole frames at 30 fps; no room after
        // it, so it ends where it did.
        let start = try #require(settled.first?.start)
        #expect(abs(start - (0.3 + 23.0 / 30)) < 0.001, "\(settled)")
        #expect(abs((settled.first?.end ?? 0) - 3.3) < 0.04, "\(settled)")
    }
}
#endif
