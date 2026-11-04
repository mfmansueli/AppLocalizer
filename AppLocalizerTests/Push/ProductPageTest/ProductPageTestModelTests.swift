//
//  ProductPageTestModelTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// “Test with Product Page Optimization…”: asking the run's design source
/// for the Outcome variant, its checks in every language, and the test
/// made through the API or, when the API won't, both variants exported,
/// never claiming a test that wasn't made.
@MainActor
@Suite("Product Page Optimization sheet")
struct ProductPageTestModelTests {
    private let folder = FileManager.default.temporaryDirectory.appending(path: "PPOModel-\(UUID().uuidString)")

    private func makeModel(
        variant: ExtrasArtworkVariant? = ExtrasReviewFixtures.variant(), environment: ProductPageTestEnvironment? = nil,
        appID: StoreApp.ID = "app-1", loaded: ScreenshotExtras? = nil
    ) throws -> ProductPageTestModel {
        var extras = ExtrasReviewFixtures.extras(previews: false)
        extras.variant = variant
        var withVariant = extras
        withVariant.variant = ExtrasReviewFixtures.variant()
        try ExtrasReviewFixtures.writeFiles(of: withVariant, into: folder)
        let planner = ExtrasReviewPlanner { [folder] id, pathExtension in folder.appending(path: "\(id).\(pathExtension)") }
        let plan = try #require(ExtrasReviewFixtures.plan(extras, appID: appID, planner: planner))
        return ProductPageTestModel(
            plan: plan, placement: .header, environment: environment,
            fileURL: { [folder] id, pathExtension in folder.appending(path: "\(id).\(pathExtension)") },
            exportFolder: folder.appending(path: "Export"), loadExtras: { loaded }
        )
    }

    @Test func itSaysWhatATestIs() {
        #expect(ProductPageTestModel.explanation
            == "Tests one idea at a time. Apple splits traffic between your current page and this treatment; results appear in App Store Connect.")
    }

    @Test func itStartsOnTheVariantWhenThereIsOne() throws {
        #expect(try makeModel().phase == .variantReady)
        #expect(try makeModel(variant: nil).phase == .intro)
        let search = ExtrasArtworkVariant(
            role: .search, kind: .search, controlIdea: "Interface", idea: "Outcome", change: "x", template: ScreenshotsSampleData.template,
            files: [], client: "Claude Code", madeAt: .now
        )
        #expect(try makeModel(variant: search).variant == nil, "A search variant isn't the header's")
    }

    @Test func eachLanguagePairsTheCurrentImageWithTheVariant() throws {
        let model = try makeModel()
        #expect(model.testName == "Header: Interface vs Outcome")
        #expect(model.rows.map(\.locale) == ["en-US", "de-DE", "fr-FR"])
        let english = try #require(model.rows.first)
        #expect(english.control?.lastPathComponent == "header-en-US-sum.png")
        #expect(english.treatment?.lastPathComponent == "variant-header-en-US.png")
        let request = try #require(model.request)
        #expect(request.locales.count == 3)
        #expect(request.placement == .header)
        #expect(request.controlName == "Interface")
        #expect(request.treatmentName == "Outcome")
        #expect(!request.startsTest, "It stays a draft the person starts")
        #expect(model.controlWaits, "The current header waits in Review & Push")
    }

    @Test func aVariantThatBreaksARuleCantBeTested() throws {
        let award = ArtworkCheck(kind: .appleRecognition, text: "German header: ‘Editor’s Choice’ — Apple’s recognitions aren’t allowed here.")
        let tester = FakeProductPageTesting()
        let model = try makeModel(variant: ExtrasReviewFixtures.variant(germanChecks: [award]), environment: ProductPageTestFixtures.environment(tester))
        #expect(model.variantErrors == [award])
        #expect(!model.canCreateTest)
        #expect(model.createBlockReason?.contains("Editor’s Choice") == true)
        model.createTest()
        #expect(model.run == nil)

        let warning = ArtworkCheck(kind: .edgeContrast, text: "German header: its edges melt into the page in Dark Mode.")
        let warned = try makeModel(variant: ExtrasReviewFixtures.variant(germanChecks: [warning]), environment: ProductPageTestFixtures.environment(tester))
        #expect(warned.canCreateTest)
    }

    @Test func withoutServicesForTestsItCantCreateOne() throws {
        let model = try makeModel(environment: nil)
        #expect(!model.canCreateTest)
        #expect(model.createBlockReason == "These services can’t make tests in App Store Connect.")
    }

    @Test func theTestIsMadeThroughTheAPI() async throws {
        let tester = FakeProductPageTesting()
        let model = try makeModel(environment: ProductPageTestFixtures.environment(tester))
        model.createTest()
        #expect(model.phase == .testing)
        await model.run?.waitUntilFinished()
        #expect(model.phase == .finished)
        let outcome = try #require(model.run?.outcome)
        #expect(outcome.isCreated)
        #expect(outcome.title == "Test created as a draft")
        #expect(tester.log.contains("create Header: Interface vs Outcome 50"))
        #expect(tester.log.contains("treatment exp-1 Outcome"))
        #expect(!tester.log.contains { $0.hasPrefix("start") })
    }

    /// One language the treatment won't take doesn't undo the others: the
    /// draft is made, and the outcome says which is missing.
    @Test func aLanguageTheTreatmentWontTakeIsNamed() async throws {
        let tester = FakeProductPageTesting(.init(refusedLocales: ["de-DE"]))
        let model = try makeModel(environment: ProductPageTestFixtures.environment(tester))
        model.createTest()
        await model.run?.waitUntilFinished()
        let outcome = try #require(model.run?.outcome)
        #expect(outcome.isCreated)
        #expect(outcome.title == "Test created as a draft")
        #expect(outcome.detail.contains("in 2 languages"))
        #expect(outcome.detail.contains("Not on the treatment: de-DE."))
        #expect(!tester.log.contains("delete exp-1"))
    }

    @Test func whenTheAPIWontTakeTheArtworkBothVariantsAreExported() async throws {
        let tester = FakeProductPageTesting(.init(refusedLocales: ["de-DE", "en-US", "fr-FR"]))
        let model = try makeModel(environment: ProductPageTestFixtures.environment(tester))
        model.createTest()
        await model.run?.waitUntilFinished()
        let outcome = try #require(model.run?.outcome)
        #expect(!outcome.isCreated)
        #expect(outcome.title == "Exported for App Store Connect")
        #expect(outcome.detail.contains("The test wasn’t created."))
        guard case let .exported(result, _) = outcome else {
            Issue.record("Expected an export, got \(outcome)")
            return
        }
        let names = Set(result.files.map(\.lastPathComponent))
        #expect(names.contains("Header – Interface – en-US.png"))
        #expect(names.contains("Header – Outcome – de-DE.png"))
        #expect(result.files.allSatisfy { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) })
        #expect(tester.log.contains("delete exp-1"), "The unfinished draft doesn't block the next test")
    }

    @Test func askingNeedsAFinishedRunAndCanBeCancelled() async throws {
        let center = AutopilotTestFixtures.center()
        let appID = StudioDebugRuns.appID
        center.install(StudioDebugExtras.run(.localize))
        let model = try makeModel(variant: nil, appID: appID)
        await model.ask(center: center, launcher: nil)
        #expect(model.phase == .intro)
        #expect(model.notice?.contains("no finished run") == true)

        center.install(StudioDebugExtras.run(.ready))
        await model.ask(center: center, launcher: nil)
        #expect(model.phase == .asking)
        let request = try #require(center.run(for: appID)?.variantRequest)
        #expect(request.role == .header)
        #expect(request.kind == .header)
        #expect(center.run(for: appID)?.assistantHasWork == true)
        #expect(model.notice == "Ask your assistant to continue Lumen Journal’s run: next_step says what to design.")

        model.cancelAsking(center: center)
        #expect(center.run(for: appID)?.variantRequest == nil)
        #expect(model.phase == .intro)
    }

    @Test func whileAskingItListsWhatsDoneAndWhatsLeft() async throws {
        let center = AutopilotTestFixtures.center()
        let appID = StudioDebugRuns.appID
        center.install(StudioDebugExtras.run(.ready))
        let model = try makeModel(variant: nil, appID: appID)
        #expect(model.steps(of: center.run(for: appID)).isEmpty, "Nothing asked yet")

        await model.ask(center: center, launcher: nil)
        #expect(model.steps(of: center.run(for: appID)).map(\.state) == [.done, .current, .upcoming, .upcoming])
        #expect(model.steps(of: center.run(for: appID)).last?.title == "AppLocalizer renders it in 3 languages and checks it")

        center.markVariantRead(appID: appID, client: "Claude Code")
        #expect(model.steps(of: center.run(for: appID)).map(\.state) == [.done, .done, .current, .upcoming])
        #expect(center.run(for: appID)?.log.last?.text == "Claude Code read what to change for the test and is designing the variant")
    }

    @Test func nobodyWorkingOnItIsIdleOnlyWhereClaudeCodeCanStart() async throws {
        let center = AutopilotTestFixtures.center()
        let appID = StudioDebugRuns.appID
        center.install(StudioDebugExtras.run(.ready))
        let model = try makeModel(variant: nil, appID: appID)
        await model.ask(center: center, launcher: nil)
        let run = center.run(for: appID)
        #expect(model.isIdle(session: nil, run: run, canStart: true))
        #expect(!model.isIdle(session: nil, run: run, canStart: false), "Without the helper the notice says to ask the assistant")

        center.update(appID) { $0.variantRequest?.receivedAt = .now }
        #expect(!model.isIdle(session: nil, run: center.run(for: appID), canStart: true), "AppLocalizer is rendering it")
    }

    @Test func continuingWithoutTheHelperSaysToAskTheAssistant() async throws {
        let center = AutopilotTestFixtures.center()
        let appID = StudioDebugRuns.appID
        center.install(StudioDebugExtras.run(.ready))
        let model = try makeModel(variant: nil, appID: appID)
        await model.ask(center: center, launcher: nil)
        model.notice = nil
        await model.continueAsking(center: center, launcher: nil)
        #expect(model.notice == "Ask your assistant to continue Lumen Journal’s run: next_step says what to design.")
        #expect(center.run(for: appID)?.variantRequest != nil, "The request stays open")
    }

    @Test func theVariantIsPickedUpOnceItArrives() async throws {
        var arrived = ExtrasReviewFixtures.extras(previews: false)
        arrived.variant = ExtrasReviewFixtures.variant()
        let model = try makeModel(variant: nil, loaded: arrived)
        model.phase = .asking
        await model.reload()
        #expect(model.phase == .variantReady)
        #expect(model.variant?.change == "A calm morning page instead of the editor")
    }
}
#endif
