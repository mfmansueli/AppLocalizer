//
//  ProductPageTestRunTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A header test from Review & Push against fake App Store Connect: made
/// through the API, stopped by a test in progress, or exported when Apple
/// won't take the artwork on a treatment. Never claims a test it didn't
/// make.
@MainActor
@Suite("Product Page Optimization test run")
struct ProductPageTestRunTests {
    private typealias Fixtures = ProductPageTestFixtures

    private func run(
        _ script: FakeProductPageTesting.Script = .init(), library: FakeAssetLibrary = FakeAssetLibrary(),
        startsTest: Bool = false, placesThroughAPI: Bool = true, size: PixelSize = Fixtures.headerSize
    ) async throws -> (ProductPageTestRun, FakeProductPageTesting, URL) {
        let folder = try Fixtures.folder()
        let tester = FakeProductPageTesting(script)
        let request = Fixtures.request(in: folder, size: size, startsTest: startsTest)
        let run = await Fixtures.run(request, environment: Fixtures.environment(tester, library: library, placesThroughAPI: placesThroughAPI))
        return (run, tester, folder)
    }

    private func exportedFiles(in folder: URL) -> [String] {
        let names = try? FileManager.default.contentsOfDirectory(atPath: folder.appending(path: "Export").path(percentEncoded: false))
        return (names ?? []).sorted()
    }

    // MARK: - Through the API

    @Test func makesADraftTestWithTheVariantInEachLanguage() async throws {
        let library = FakeAssetLibrary()
        let (run, tester, folder) = try await run(library: library)

        let outcome = try #require(run.outcome)
        guard case let .created(created) = outcome else {
            Issue.record("Expected a created test, got \(outcome)")
            return
        }
        #expect(created.experimentID == "exp-1")
        #expect(created.treatmentID == "tr-1")
        #expect(created.placedLocales == ["en-US", "de-DE"])
        #expect(created.failedLocales.isEmpty)
        #expect(!created.isStarted)
        #expect(outcome.title == "Test created as a draft")
        #expect(created.summary.contains("is a draft in App Store Connect"))
        #expect(created.summary.contains("Start it there"))

        let group = AssetLibraryRefDataSample.headerGroup
        let header = ExtrasPushKind.productPageHeader
        #expect(tester.log == [
            "tests app-1",
            "create Header: Interface vs Outcome 50",
            "treatment exp-1 Outcome",
            "locale tr-1 en-US",
            "place image-1 \(header) \(group) trl-en-US",
            "locale tr-1 de-DE",
            "place image-2 \(header) \(group) trl-de-DE",
        ])
        // Uploaded as creative assets, processed before placing.
        let size = Data("bytes of header-outcome-de-DE.png".utf8).count
        #expect(library.log.contains("reserve image header-outcome-de-DE.png \(size) CREATIVE_ASSETS"))
        #expect(library.log.contains("commit image-2"))
        #expect(run.status(of: "en-US") == .done(assetID: "image-1", placementIDs: ["pl-trl-en-US"]))
        #expect(run.status(of: "de-DE").isDone)
        #expect(run.phase == .finished)
        #expect(run.step == nil)
        // Nothing exported when the test was made.
        #expect(exportedFiles(in: folder).isEmpty)
    }

    @Test func itsSentToReviewOnlyWhenAsked() async throws {
        let (run, tester, _) = try await run(startsTest: true)

        guard case let .created(created) = run.outcome else {
            Issue.record("Expected a created test")
            return
        }
        #expect(created.isStarted)
        #expect(tester.log.last == "start exp-1")
        #expect(run.outcome?.title == "Test sent to App Review")
    }

    @Test func aRefusedStartStillLeavesTheDraftAndSaysWhy() async throws {
        let (run, _, _) = try await run(.init(startFails: true), startsTest: true)

        guard case let .created(created) = run.outcome else {
            Issue.record("Expected a created test")
            return
        }
        #expect(!created.isStarted)
        #expect(created.summary.contains("is a draft"))
        #expect(created.summary.contains("couldn’t be sent to App Review (STATE_ERROR — The treatment has no screenshots)"))
    }

    // MARK: - A test in the way

    @Test func aTestInProgressIsReportedAndNothingIsCreated() async throws {
        let current = ProductPageExperiment(id: "exp-0", name: "Icon test", platform: "IOS", state: "APPROVED")
        let (run, tester, folder) = try await run(.init(tests: [current]))

        #expect(run.outcome == .testInProgress(name: "Icon test", state: "running"))
        #expect(run.outcome?.isCreated == false)
        #expect(run.outcome?.detail.contains("“Icon test” is running") == true)
        #expect(run.outcome?.detail.contains("Nothing was created.") == true)
        #expect(tester.log == ["tests app-1"])
        #expect(exportedFiles(in: folder).isEmpty)
    }

    @Test func finishedTestsAndOtherPlatformsDontBlock() async throws {
        let done = ProductPageExperiment(id: "exp-0", name: "Icons", platform: "IOS", state: "COMPLETED")
        let mac = ProductPageExperiment(id: "exp-m", name: "Mac", platform: "MAC_OS", state: "APPROVED")
        let (run, _, _) = try await run(.init(tests: [done, mac]))

        #expect(run.outcome?.isCreated == true)
    }

    @Test func aDraftTheListDidntShowIsReportedToo() async throws {
        let (run, tester, _) = try await run(.init(refusesNewTest: true))

        #expect(run.outcome == .testInProgress(name: nil, state: "in progress"))
        #expect(tester.log == ["tests app-1", "create Header: Interface vs Outcome 50"])
    }

    // MARK: - Falling back to the export

    @Test func aRefusedPlacementDeletesTheDraftAndExportsBothVariants() async throws {
        let (run, tester, folder) = try await run(.init(refusedLocales: ["en-US"]))

        let outcome = try #require(run.outcome)
        guard case let .exported(result, reason) = outcome else {
            Issue.record("Expected an export, got \(outcome)")
            return
        }
        #expect(!outcome.isCreated)
        #expect(outcome.title == "Exported for App Store Connect")
        #expect(reason.contains("didn’t take the product page header on the test’s treatment"))
        #expect(reason.contains("ENTITY_ERROR.RELATIONSHIP.INVALID"))
        #expect(reason.contains("The unfinished draft was deleted."))
        #expect(outcome.detail.contains("The test wasn’t created."))
        #expect(tester.log.last == "delete exp-1")
        // The other language wasn't tried.
        #expect(!tester.log.contains("locale tr-1 de-DE"))
        #expect(run.status(of: "de-DE") == .cancelled)
        #expect(exportedFiles(in: folder) == [
            "Header – Interface – de-DE.png", "Header – Interface – en-US.png", "Header – Outcome – de-DE.png", "Header – Outcome – en-US.png",
        ])
        #expect(result.steps.contains("create a test with one treatment named “Outcome”"))
    }

    @Test func aDraftThatCantBeDeletedIsNamed() async throws {
        let (run, _, _) = try await run(.init(refusedLocales: ["en-US"], deleteFails: true))

        guard case let .exported(_, reason) = run.outcome else {
            Issue.record("Expected an export")
            return
        }
        #expect(reason.contains("The unfinished draft “Header: Interface vs Outcome” couldn’t be deleted"))
        #expect(reason.contains("delete it in App Store Connect before making another test"))
    }

    @Test func aRefusalAfterALanguageWasPlacedFailsOnlyThatLanguage() async throws {
        let (run, tester, folder) = try await run(.init(refusedLocales: ["de-DE"]))

        guard case let .created(created) = run.outcome else {
            Issue.record("Expected a created test")
            return
        }
        #expect(created.placedLocales == ["en-US"])
        #expect(created.failedLocales["de-DE"]?.contains("didn’t take the product page header") == true)
        #expect(created.summary.contains("Not on the treatment: de-DE."))
        #expect(run.status(of: "de-DE").isFailure)
        #expect(!tester.log.contains("delete exp-1"))
        #expect(exportedFiles(in: folder).isEmpty)
    }

    @Test func withoutTheAPIItOnlyExports() async throws {
        let library = FakeAssetLibrary()
        let (run, tester, folder) = try await run(library: library, placesThroughAPI: false)

        guard case let .exported(_, reason) = run.outcome else {
            Issue.record("Expected an export")
            return
        }
        #expect(reason == "App Store Connect’s API can’t put the product page header on a test’s treatment.")
        #expect(tester.log.isEmpty)
        #expect(library.log.isEmpty)
        #expect(exportedFiles(in: folder).count == 4)
    }

    // MARK: - Failures

    @Test func offlineStopsTheRunAndRemovesTheDraft() async throws {
        let library = FakeAssetLibrary(.init(offline: ["header-outcome-en-US"]))
        let (run, tester, folder) = try await run(library: library)

        guard case let .failed(reason) = run.outcome else {
            Issue.record("Expected a failure")
            return
        }
        #expect(reason.hasPrefix("This Mac is offline."))
        #expect(tester.log.last == "delete exp-1")
        #expect(run.status(of: "en-US").isFailure)
        #expect(run.status(of: "de-DE") == .cancelled)
        #expect(exportedFiles(in: folder).isEmpty)
    }

    @Test func aSizeNoGroupTakesFailsBeforeUploading() async throws {
        let library = FakeAssetLibrary()
        let (run, tester, _) = try await run(library: library, size: PixelSize(width: 3000, height: 1000))

        guard case let .failed(reason) = run.outcome else {
            Issue.record("Expected a failure")
            return
        }
        #expect(reason.hasPrefix("No language’s variant went on the treatment."))
        #expect(run.status(of: "en-US").failureReason?.contains("doesn’t take a 3000 × 1000 image") == true)
        #expect(!library.log.contains { $0.hasPrefix("reserve") })
        #expect(tester.log.last == "delete exp-1")
    }
}
