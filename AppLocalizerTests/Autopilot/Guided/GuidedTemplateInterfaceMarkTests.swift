//
//  GuidedTemplateInterfaceMarkTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Look's template preview marks a screenshot whose device was never
/// captured in the language (board 21: Lumen's iPad exists in 4
/// languages): the note says so, and the viewer's line under the title
/// adds "English interface, not captured in this language yet".
@MainActor
@Suite("Guided look · English interface mark")
struct GuidedTemplateInterfaceMarkTests {
    /// The screenshots model is returned too: the studio holds it unowned.
    private static func studio() async -> (ScreenshotsViewModel, AutopilotPlan) {
        let run = StudioDebugRuns.run(.plan)
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run))
        return (model, run.plan)
    }

    @Test func aLanguageTheIPadWasNeverCapturedInIsMarkedInTheViewer() async throws {
        let (model, plan) = await Self.studio()
        model.studio.guided.templateDevice = .iPad
        model.studio.guided.templateLocale = "ar-SA"
        let preview = try #require(model.studio.templatePreview(.arcade, plan: plan))
        let allMarked = preview.items.allSatisfy(\.showsPrimaryInterface)
        try #require(allMarked, "Lumen's iPad isn't captured in Arabic")
        #expect(preview.note.contains("(marked)"), "\(preview.note)")

        let items = model.studio.templateViewerItems(.arcade, plan: plan)
        #expect(!items.isEmpty)
        for item in items {
            #expect(item.subtitle.hasSuffix(" · English interface, not captured in this language yet"), "\(item.subtitle)")
            #expect(item.subtitle.contains("Arabic"))
        }
    }

    @Test func aCapturedLanguageIsNotMarked() async throws {
        let (model, plan) = await Self.studio()
        model.studio.guided.templateDevice = .iPad
        model.studio.guided.templateLocale = "de-DE"
        let preview = try #require(model.studio.templatePreview(.arcade, plan: plan))
        let anyMarked = preview.items.contains { $0.showsPrimaryInterface }
        #expect(!anyMarked)
        for item in model.studio.templateViewerItems(.arcade, plan: plan) {
            #expect(!item.subtitle.contains("English interface"), "\(item.subtitle)")
        }
    }
}
#endif
