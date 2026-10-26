//
//  AppInformationViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The section's view model on the sample services (canned data, notes and
/// the demo password in memory): loading, edits queuing changes, an
/// assistant's answers, the Keychain password and export answers.
@MainActor
@Suite("AppInformationViewModel")
struct AppInformationViewModelTests {
    private let queue = ChangeQueue()
    private let app = StoreApp(id: DebugFixtures.AppID.lumen, name: "Lumen Journal", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")

    private func loaded(_ services: DebugAppInformationServices = DebugAppInformationServices()) async -> AppInformationViewModel {
        let viewModel = AppInformationViewModel(app: app, services: services, queue: queue)
        await viewModel.load()
        return viewModel
    }

    @Test func loadsThePagesAndTheirStatuses() async {
        let vm = await loaded()
        #expect(vm.isLoaded)
        #expect(vm.content?.version?.versionString == "1.4")
        #expect(vm.status(for: .general) == "Lifestyle · Health & Fitness")
        #expect(vm.status(for: .accessibility) == "1 published · 1 not declared")
        #expect(vm.status(for: .appReview) == "Complete")
        #expect(vm.status(for: .exportCompliance) == "Exempt")
        #expect(vm.status(for: .appPrivacy) == nil)
    }

    @Test func aFailedLoadSaysWhyAndKeepsNothing() async {
        let vm = await loaded(DebugAppInformationServices(error: .server(statusCode: 500, detail: nil)))
        #expect(!vm.isLoaded)
        #expect(vm.errorMessage != nil)
    }

    @Test func anEditQueuesAChangeAndUndoingItDiscardsIt() async throws {
        let vm = await loaded()
        vm.setCopyright("© 2027 Northpier Studio")
        let change = try #require(queue.changes.first)
        #expect(change.newValue == "© 2027 Northpier Studio")
        #expect(vm.general?.copyright == "© 2027 Northpier Studio")
        #expect(vm.hasPendingChanges(on: .general))

        vm.setCopyright("© 2026 Northpier Studio")
        #expect(queue.changes.isEmpty)
        #expect(!vm.hasPendingChanges(on: .general))
    }

    @Test func aLiveVersionIsReadOnly() async {
        let vm = await loaded()
        await vm.selectVersion(DebugAppInformationContent.liveVersionID)
        #expect(vm.content?.version?.versionString == "1.3")
        #expect(!vm.isReviewEditable)
        vm.setReviewText("someone@example.com", for: .email)
        #expect(queue.changes.isEmpty)
    }

    @Test func yourAnswerReplacesAnAssistantsAndConfirmingUnblocksIt() async throws {
        let vm = await loaded()
        let assistant = DebugAppInformationChanges.assistantAgeAnswers(confirmed: [])
        queue.upsert(contentsOf: assistant)
        #expect(vm.assistantAnswers.count == 7)
        #expect(vm.assistantBanner?.text == "answered 7 questions from the project · 7 not confirmed yet")
        #expect(vm.ratingPreview?.calculated == .ninePlus)
        #expect(vm.ratingChanges)

        vm.confirmAnswer(.wellness, true)
        let wellness = try #require(queue.change(id: vm.builder.changeID(.ageRating, "wellness")))
        #expect(wellness.blockedReason == nil)
        #expect(wellness.source.isAssistant)

        vm.setAnswer(.affirmative, for: .advertising)
        let advertising = try #require(queue.change(id: vm.builder.changeID(.ageRating, "advertising")))
        #expect(advertising.source == .you)
        #expect(vm.assistantAnswers[.advertising] == nil)

        vm.rejectAnswer(.messaging)
        #expect(queue.change(id: vm.builder.changeID(.ageRating, "messaging")) == nil)
        #expect(vm.evidence(for: .messaging) == nil)
    }

    @Test func theOverrideKeepsItsReasonOnThisMac() async throws {
        let vm = await loaded()
        vm.setOverrideOn(true)
        let blocked = try #require(queue.change(id: vm.builder.changeID(.ageRating, "override")))
        #expect(blocked.blockedReason != nil)
        vm.setOverrideReason("Reflections can touch on grief.")
        #expect(vm.notes.overrideReason == "Reflections can touch on grief.")
        #expect(vm.services.notes.notes(for: app.id).overrideReason == "Reflections can touch on grief.")
        #expect(queue.change(id: vm.builder.changeID(.ageRating, "override"))?.blockedReason == nil)
        #expect(vm.ageRating?.override == .ninePlus)
    }

    @Test func thePasswordGoesToTheSecretStoreNeverTheQueue() async throws {
        let vm = await loaded()
        vm.setSignInRequired(true)
        vm.setReviewText("review@northpier.dev", for: .userName)
        vm.setReviewText("sandbox-2026", for: .password)
        #expect(try vm.services.secrets.secret(named: vm.builder.passwordSecretName) == "sandbox-2026")
        #expect(vm.review?.password == "sandbox-2026")
        let encoded = try String(data: JSONEncoder().encode(queue.changes), encoding: .utf8)
        #expect(encoded?.contains("sandbox-2026") == false)
        #expect(queue.changes.count == 3)
    }

    @Test func exportAnswersStayHereAndOnlyTheFlagIsQueued() async throws {
        let vm = await loaded()
        vm.setExportAnswer(false, for: .isExempt)
        #expect(vm.notes.exportAnswers?[.isExempt] == false)
        let change = try #require(queue.change(id: vm.builder.encryptionChangeID))
        #expect(change.requests.first?.path == "/v1/builds/\(DebugAppInformationContent.buildID)")
        #expect(vm.exportAnswers?.status == "Docs needed")

        vm.rejectExportEvidence()
        #expect(vm.notes.exportEvidence == nil)
        #expect(vm.notes.exportAnswers == nil)
        #expect(queue.changes.isEmpty)
    }
}
