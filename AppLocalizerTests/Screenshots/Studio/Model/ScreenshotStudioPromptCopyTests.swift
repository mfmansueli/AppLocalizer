//
//  ScreenshotStudioPromptCopyTests.swift
//  AppLocalizerTests
//

#if DEBUG
import AppKit
import Testing
@testable import AppLocalizer

/// Start Autopilot and Copy Again put the prompt on the clipboard. These
/// use the general pasteboard, so they run one at a time and put back
/// what was there.
@MainActor
@Suite("ScreenshotStudioModel · Copying the prompt", .serialized)
struct ScreenshotStudioPromptCopyTests {
    @Test func startWaitsForTheAssistantWithThePromptCopied() async throws {
        try await Self.keepingThePasteboard {
            let center = StudioTestFixtures.center(StudioDebugRuns.run(.plan))
            let model = await StudioTestFixtures.screenshots(center: center)
            model.studio.viewedStep = .plan
            model.studio.start()
            let run = try #require(center.run(for: StudioTestFixtures.app.id))
            #expect(run.stage == .waiting)
            #expect(run.startedAt == StudioTestFixtures.now)
            #expect(run.designKind == .none)
            #expect(model.studio.viewedStep == nil)
            #expect(model.studio.guidedStep == .making)
            #expect(model.studio.didCopyPrompt)
            #expect(!model.studio.prompt.isEmpty)
            #expect(NSPasteboard.general.string(forType: .string) == model.studio.prompt)
        }
    }

    @Test func startTakesTheDesignProjectConnectedNow() async throws {
        try await Self.keepingThePasteboard {
            let center = StudioTestFixtures.center(StudioDebugRuns.run(.plan, design: false), project: StudioDebugRuns.northpier)
            let model = await StudioTestFixtures.screenshots(center: center)
            model.studio.start()
            let run = try #require(center.run(for: StudioTestFixtures.app.id))
            #expect(run.designKind == .claudeDesign)
            #expect(run.designName == "Northpier Brand")
        }
    }

    @Test func copyAgainCopiesThePromptOnceMore() async throws {
        try await Self.keepingThePasteboard {
            let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(StudioDebugRuns.run(.waiting)))
            NSPasteboard.general.clearContents()
            #expect(!model.studio.didCopyPrompt)
            model.studio.copyPrompt()
            #expect(model.studio.didCopyPrompt)
            #expect(NSPasteboard.general.string(forType: .string) == model.studio.prompt)
        }
    }

    /// Runs `body`, then puts the pasteboard's text back.
    private static func keepingThePasteboard(_ body: () async throws -> Void) async throws {
        let saved = NSPasteboard.general.string(forType: .string)
        defer {
            NSPasteboard.general.clearContents()
            if let saved { NSPasteboard.general.setString(saved, forType: .string) }
        }
        try await body()
    }
}
#endif
