//
//  SuggestionRunTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Suggest Everything in the store: the run waits, takes the assistant's
/// plan, counts what arrives apart from a per-page Ask, says what each page
/// covers, and stops.
@MainActor
@Suite("SuggestionRun")
struct SuggestionRunTests {
    private let clock = TestClock()
    private let appID = "6450000001"
    private let claude = SuggestionSource.assistant(client: "Claude Code")
    private let whatsNew = SuggestionTarget.storePage(.englishUS, .whatsNew)
    private let subtitle = SuggestionTarget.storePage(.englishUS, .subtitle)
    private let germanWhatsNew = SuggestionTarget.storePage(.german, .whatsNew)
    private let secondaryCategory = SuggestionTarget.appInformation(.secondaryCategory)
    private let iPhoneVoiceOver = AppInformationSuggestionSlot.accessibility(.iPhone, .voiceOver).target
    private let watchVoiceOver = AppInformationSuggestionSlot.accessibility(.appleWatch, .voiceOver).target

    private func store() -> FieldSuggestionStore {
        FieldSuggestionStore(now: { [clock] in clock.now })
    }

    private func add(_ target: SuggestionTarget, to store: FieldSuggestionStore, runID: SuggestionRun.ID? = nil, value: String = "New") {
        store.add(appID: appID, target: target, value: value, reason: "", source: claude, runID: runID)
    }

    @Test func suggestEverythingWaitsThenTakesThePlan() {
        let store = store()
        store.beginRun(appID: appID, client: "Claude Code", prompt: "Suggest everything…")
        #expect(store.run?.phase == .waiting)
        #expect(store.run?.id == "run_1")

        let run = store.startRun(appID: appID, client: "Claude Code", plan: [whatsNew, subtitle, whatsNew])
        #expect(run.id == "run_1")
        #expect(run.prompt == "Suggest everything…")
        #expect(run.phase == .running)
        #expect(run.plan == [whatsNew, subtitle])
        #expect(run.progressText == "Suggesting everything · 0 of 2")
    }

    @Test func anAssistantThatStartsOnItsOwnGetsANewRun() {
        let store = store()
        store.beginRun(appID: appID, client: "Cursor", prompt: "Suggest everything…")
        let run = store.startRun(appID: appID, client: "Claude Code", plan: [whatsNew])
        #expect(run.id == "run_2")
        #expect(run.prompt.isEmpty)
    }

    @Test func anEmptyPlanIsOverAtOnce() {
        let store = store()
        let run = store.startRun(appID: appID, client: "Claude Code", plan: [])
        #expect(run.phase == .finished)
        #expect(run.finishedText == "Claude Code looked at everything and found nothing new to suggest.")
    }

    @Test func arrivalsCountTowardTheRunAndNotTheAsk() throws {
        let store = store()
        store.beginRequest(appID: appID, area: .storePage, client: "Claude Code", prompt: "Suggest Store Page text…")
        let id = store.startRun(appID: appID, client: "Claude Code", plan: [whatsNew, secondaryCategory]).id

        add(whatsNew, to: store, runID: id)
        #expect(store.run?.received == 1)
        #expect(store.request?.received == 0)

        // Planned, so it counts even without the run's id.
        add(secondaryCategory, to: store)
        let run = try #require(store.run)
        #expect(run.phase == .finished)
        #expect(run.suggestionIDs.count == 2)
        #expect(store.request?.received == 0)
    }

    @Test func somethingOutsideThePlanSentWithTheRunAddsToTheTotal() {
        let store = store()
        let id = store.startRun(appID: appID, client: "Claude Code", plan: [whatsNew, subtitle]).id
        add(germanWhatsNew, to: store, runID: id)
        #expect(store.run?.total == 3)
        #expect(store.run?.received == 1)
        // Without the run's id, it's an ordinary suggestion.
        add(.storePage(.japanese, .whatsNew), to: store)
        #expect(store.run?.total == 3)
    }

    @Test func aFieldThatAlreadyHeldTheValueCountsAsArrived() {
        let store = store()
        let id = store.startRun(appID: appID, client: "Claude Code", plan: [whatsNew]).id
        store.noteSettled(whatsNew, appID: appID, source: claude, runID: id)
        #expect(store.run?.phase == .finished)
        #expect(store.run?.suggestionIDs.isEmpty == true)
    }

    @Test func rowsSayWhatEachPageCovers() throws {
        let store = store()
        let id = store.startRun(
            appID: appID,
            client: "Claude Code",
            plan: [whatsNew, subtitle, germanWhatsNew, secondaryCategory, iPhoneVoiceOver, watchVoiceOver]
        ).id
        add(whatsNew, to: store, runID: id)
        add(subtitle, to: store, runID: id)
        add(iPhoneVoiceOver, to: store, runID: id, value: "yes")

        let rows = try #require(store.run?.rows)
        #expect(rows.map(\.page) == [.storePage, .general, .accessibility])
        #expect(rows[0].detail == "English (U.S.) 2/2 · German 0/1")
        #expect(rows[0].progressText == "2 of 3")
        #expect(rows[1].detail == "Secondary Category")
        #expect(rows[2].detail == "iPhone 1/1 · Apple Watch 0/1")
        #expect(store.run?.comingCount(on: .storePage) == 1)
        #expect(store.run?.isComing(germanWhatsNew) == true)
        #expect(store.run?.isComing(whatsNew) == false)
        #expect(store.run?.comingCount(in: [.storePage(.german)]) == 1)
        #expect(store.run?.hereText(in: [.storePage(.englishUS)]) == "Here: 2 of 2 arrived.")

        store.stopRun()
        let stopped = try #require(store.run?.rows)
        #expect(stopped[0].detail == "English (U.S.) 2 · German 0")
        #expect(stopped[0].countText == "2 suggestions")
        #expect(store.run?.isComing(germanWhatsNew) == false)
        #expect(store.run?.finishedText == "Claude Code sent 3 suggestions: Store Page 2 · Accessibility 1.")
    }

    @Test func stopReceivingKeepsWhatArrivedAndCountsNothingMore() {
        let store = store()
        let id = store.startRun(appID: appID, client: "Claude Code", plan: [whatsNew, subtitle]).id
        add(whatsNew, to: store, runID: id)
        store.stopRun()
        #expect(store.run?.phase == .stopped)
        #expect(store.isStopped(id))

        add(subtitle, to: store, runID: id)
        #expect(store.run?.received == 1)
        store.dismissRun()
        #expect(store.run == nil)
        #expect(store.isStopped(id))
    }

    @Test func endingKeepsWhatArrived() {
        let store = store()
        let id = store.startRun(appID: appID, client: "Claude Code", plan: [whatsNew, subtitle]).id
        add(whatsNew, to: store, runID: id)
        store.endRun(id: "run_9")
        #expect(store.run?.phase == .running)
        store.endRun(id: id)
        #expect(store.run?.phase == .finished)
        #expect(store.run?.finishedText == "Claude Code sent 1 suggestion: Store Page 1.")
    }

    @Test func aRunGoesQuietAfterTwoMinutesWithoutAnything() throws {
        let store = store()
        let id = store.startRun(appID: appID, client: "Claude Code", plan: [whatsNew, subtitle]).id
        clock.advance(by: 90)
        add(whatsNew, to: store, runID: id)
        clock.advance(by: 119)
        #expect(store.run?.isQuiet(at: clock.now) == false)
        clock.advance(by: 1)
        let run = try #require(store.run)
        #expect(run.isQuiet(at: clock.now))
        #expect(run.quietText == "Claude Code stopped sending · 1 of 2")
    }

    @Test func theCardSaysWhereTheRunIs() {
        let store = store()
        let id = store.startRun(appID: appID, client: "Claude Code", plan: [whatsNew, subtitle]).id
        add(whatsNew, to: store, runID: id)
        #expect(store.run?.title == "Suggesting everything")
        #expect(store.run?.countText == "1 of 2")
        store.stopRun()
        #expect(store.run?.title == "Stopped receiving")
        #expect(store.run?.countText == "1 suggestions of 2")

        let other = store.startRun(appID: appID, client: "Claude Code", plan: [whatsNew]).id
        add(whatsNew, to: store, runID: other, value: "Newer")
        #expect(store.run?.title == "Finished suggesting")
        #expect(store.run?.countText == "1 suggestion")
    }

    @Test func dismissingAWaitingRunForgetsIt() {
        let store = store()
        store.beginRun(appID: appID, client: "Claude Code", prompt: "Suggest everything…")
        store.dismissRun()
        #expect(store.run == nil)
    }

    @Test func anAskCoversTheFieldsItsPromptAsksFor() {
        let storePage = AssistantSuggestionRequest(appID: appID, area: .storePage, client: "Claude Code", prompt: "", startedAt: clock.now)
        #expect(storePage.covers(germanWhatsNew))
        #expect(storePage.covers(subtitle))
        #expect(!storePage.covers(.storePage(.englishUS, .keywords)))
        #expect(!storePage.covers(secondaryCategory))

        let information = AssistantSuggestionRequest(appID: appID, area: .appInformation, client: "Claude Code", prompt: "", startedAt: clock.now)
        #expect(information.covers(secondaryCategory))
        #expect(information.covers(.appInformation(.notes)))
        #expect(!information.covers(iPhoneVoiceOver))
        #expect(!information.covers(whatsNew))
    }

    @Test func pagesComeFromScopes() {
        #expect(SuggestionPage(.storePage(.german)) == .storePage)
        #expect(SuggestionPage(.appInformation(.ageRating)) == .ageRating)
        #expect(SuggestionPage(.appInformation(.appReview)) == .appReview)
        #expect(SuggestionPage(.accessibility(.appleWatch)) == .accessibility)
        #expect(SuggestionPage(.appInformation(.appPrivacy)) == nil)
        #expect(SuggestionPage.fieldTitle(of: AppInformationSuggestionSlot.ageRating(.wellness).target) == "Health or wellness topics")
    }
}
