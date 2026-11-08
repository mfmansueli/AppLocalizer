//
//  TwoPhonesMatrixTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Two phones in the Sets matrix: the phone behind shows the slot before's
/// capture, and that capture is part of the render key, so re-capturing it
/// renders the slot again.
@MainActor
@Suite("Two phones matrix")
struct TwoPhonesMatrixTests {
    private func arcadeDocument() throws -> ScreenshotsDocument {
        var document = ScreenshotsDebugDocuments.standard
        var history = try #require(document.history)
        let arcade = ScreenshotTemplate.starter(.arcade, id: "lumen", title: "Lumen", slotCount: document.slotCount(on: .iPhone))
        history.save(arcade, date: .now, note: "Arcade")
        document.history = history
        return document
    }

    private func job(_ matrix: ScreenshotMatrix, slot: Int) throws -> RenderJob {
        let cell = try #require(matrix.cell(locale: "en-US", displayType: .iPhone, slot: slot))
        guard case let .render(job) = cell.image else {
            Issue.record("Slot \(slot + 1) isn't rendered: \(cell.image)")
            throw CancellationError()
        }
        return job
    }

    @Test func thePhoneBehindShowsTheSlotBefore() throws {
        let document = try arcadeDocument()
        let matrix = ScreenshotsTestFixtures.matrix(document)
        let third = try job(matrix, slot: 2)
        let primary = document.scope.primary
        let second = try #require(document.captures.capture(locale: "en-US", displayType: .iPhone, slot: 1, primary: primary))
        let own = try #require(document.captures.capture(locale: "en-US", displayType: .iPhone, slot: 2, primary: primary))
        #expect(third.companion?.id == second.capture.id)
        #expect(third.capture?.id == own.capture.id)
        #expect(third.layout.companion?.isBehind == true)
    }

    @Test func slotsWithOnePhoneHaveNothingBehind() throws {
        let matrix = try ScreenshotsTestFixtures.matrix(arcadeDocument())
        for slot in [0, 1, 3, 4] {
            let rendered = try job(matrix, slot: slot)
            #expect(rendered.companion == nil, "Slot \(slot + 1)")
            #expect(rendered.layout.companion == nil, "Slot \(slot + 1)")
        }
    }

    @Test func theCaptureBehindIsPartOfTheRenderKey() throws {
        let document = try arcadeDocument()
        let matrix = ScreenshotsTestFixtures.matrix(document)
        let cell = try #require(matrix.cell(locale: "en-US", displayType: .iPhone, slot: 2))
        let third = try job(matrix, slot: 2)
        let template = try #require(document.template)
        let own = try #require(third.capture?.id)
        let behind = try #require(third.companion?.id)
        func key(_ captureID: String) -> RenderKey {
            RenderKey(templateHash: template.contentHash, locale: "en-US", displayType: .iPhone, slot: 2, caption: cell.caption, captureID: captureID)
        }
        #expect(third.key == key("\(own)+\(behind)"))
        #expect(third.key != key(own))
    }
}
#endif
