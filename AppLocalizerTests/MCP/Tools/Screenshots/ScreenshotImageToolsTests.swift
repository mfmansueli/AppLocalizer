//
//  ScreenshotImageToolsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// `get_capture`, `render_preview` and `measure_caption`: what an
/// assistant sees and measures before proposing.
@MainActor
@Suite("Screenshot image and measuring tools")
struct ScreenshotImageToolsTests {
    private let fixture = MCPScreenshotsFixtures.workspace()

    private func call(_ tool: some MCPTool, _ arguments: [String: JSONValue]) async throws -> MCPToolOutcome {
        try await MCPScreenshotsFixtures.call(tool, arguments, in: fixture.0)
    }

    private static let pngSignature = Data([0x89, 0x50, 0x4E, 0x47])

    @Test func aCaptureComesBackAsAPNG() async throws {
        let outcome = try await call(GetCaptureTool(), ["captureId": "de-DE|APP_IPHONE_67|2"])
        #expect(!outcome.isError)
        #expect(outcome.result == [
            "captureId": "de-DE|APP_IPHONE_67|2", "locale": "de-DE", "displayType": "iphone", "slot": 3,
            "fileName": "de-DE/iPhone 17 Pro Max-03_Search.png",
        ])
        let image = try #require(outcome.images.first)
        #expect(image.mimeType == "image/png")
        #expect(image.data.prefix(4) == Self.pngSignature)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · de-DE · slot 3", outcome: .read)])
        let content = try #require(outcome.callResult["content"]?.arrayValue)
        #expect(content.count == 2)
        #expect(content[1]["type"] == "image")
    }

    @Test func anUnknownCaptureIsNotFound() async {
        await #expect(throws: MCPToolError.self) { try await call(GetCaptureTool(), ["captureId": "nope"]) }
    }

    @Test func aPreviewRendersTheSlotWithItsFit() async throws {
        let outcome = try await call(RenderPreviewTool(), ["locale": "de-DE", "slot": 3, "displayType": "iphone"])
        #expect(outcome.result["slot"] == 3)
        #expect(outcome.result["localizedUI"] == true)
        #expect(outcome.result["fit"]?["fits"] == false)
        #expect(outcome.images.first?.data.prefix(4) == Self.pngSignature)

        let patched = try await call(RenderPreviewTool(), [
            "locale": "de-DE", "slot": 3, "displayType": "iphone", "templatePatch": ["fit.hyphenate": true, "caption.headline.min": 60],
        ])
        #expect(patched.result["fit"]?["fits"] == true)
    }

    @Test func slotsAreNumberedFromOne() async {
        await #expect(throws: MCPToolError.invalidArgument(name: "slot", expected: "a slot from 1 to 5")) {
            try await call(RenderPreviewTool(), ["locale": "de-DE", "slot": 0, "displayType": "iphone"])
        }
        await #expect(throws: MCPToolError.invalidArgument(name: "slot", expected: "a slot from 1 to 5")) {
            try await call(MeasureCaptionTool(), ["locale": "de-DE", "slot": 6, "headline": "Hallo"])
        }
    }

    @Test func measuringSaysWhetherAHeadlineFits() async throws {
        let long = try await call(MeasureCaptionTool(), [
            "locale": "de-DE", "slot": 3, "headline": "Durchsuche jahrelange Tagebucheinträge in nur wenigen Sekunden",
        ])
        #expect(long.result["fits"] == false)
        #expect(long.result["maxLines"] == 2)
        #expect(long.result["glyphsMissing"] == "")
        #expect(long.logLines == [.init(target: "Lumen Journal · de-DE · slot 3", outcome: .read)])

        let short = try await call(MeasureCaptionTool(), ["locale": "de-DE", "slot": 3, "headline": "Einträge aus Jahren in Sekunden finden"])
        #expect(short.result["fits"] == true)
        #expect(short.result["size"] == 112)
    }

    @Test func aPatchThatDoesntApplyIsAnInvalidArgument() async {
        await #expect(throws: MCPToolError.self) {
            try await call(MeasureCaptionTool(), ["locale": "de-DE", "slot": 1, "headline": "Hallo", "templatePatch": ["caption.glow": true]])
        }
    }
}
