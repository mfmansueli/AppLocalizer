//
//  PriceScheduleTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("PriceSchedule")
struct PriceScheduleTests {
    private let scheduled = PriceSchedule(startDay: "2026-11-02")

    @Test func immediateIsTheDefault() {
        let schedule = PriceSchedule.immediate
        #expect(!schedule.isScheduled)
        #expect(schedule.startDate == nil)
        #expect(schedule.buttonTitle == "Starts now")
        #expect(schedule.note == "Prices change as soon as Apple processes them · existing subscribers keep their price")
    }

    @Test func aStartDayNamesItsDate() {
        #expect(scheduled.isScheduled)
        #expect(scheduled.buttonTitle == "Starts Nov 2, 2026")
        #expect(scheduled.note == "Prices change on Nov 2, 2026 · existing subscribers keep their price")
        let everyone = PriceSchedule(startDay: "2026-11-02", preservesCurrentPrice: false)
        #expect(everyone.note == "Prices change on Nov 2, 2026")
    }

    @Test func daysRoundTripThroughThePickersCalendar() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Sao_Paulo"))
        let date = try #require(PriceSchedule.date(ofDay: "2026-11-02", in: calendar))
        #expect(PriceSchedule.day(of: date, in: calendar) == "2026-11-02")
        #expect(PriceSchedule.date(ofDay: "next week") == nil)
    }

    @Test func applyingRewritesThePriceWriteButNotTheRestore() async throws {
        let matrix = try await PricingModelFixtures.matrix(follows: true)
        let brazil = try #require(matrix.queue.change(id: "price.\(DebugPricingCatalog.lumenAnnualID).BRA"))

        let rewritten = scheduled.applied(to: brazil)

        #expect(PriceSchedule(change: rewritten) == scheduled)
        #expect(rewritten.groupNote == scheduled.note)
        #expect(rewritten.restoreRequests == brazil.restoreRequests)
        let request = try decode(rewritten.requests.first)
        let original = try decode(brazil.requests.first)
        #expect(request.data.attributes.startDate == "2026-11-02")
        #expect(request.data.attributes.preserveCurrentPrice)
        #expect(request.pricePointID == original.pricePointID)
        #expect(original.data.attributes.startDate == nil)
    }

    @Test func theQueueKeepsTheSchedule() async throws {
        let queue = ChangeQueue()
        let matrix = try await PricingModelFixtures.matrix(queue: queue, follows: true)
        #expect(PriceSchedule.current(in: queue, appID: PricingModelFixtures.appID, productID: matrix.product.id) == .immediate)

        matrix.setSchedule(scheduled)

        #expect(PriceSchedule.current(in: queue, appID: PricingModelFixtures.appID, productID: matrix.product.id) == scheduled)
        #expect(queue.changes.allSatisfy { PriceSchedule(change: $0) == scheduled })
        let queuedAreScheduled = matrix.rows.filter { $0.queued != nil }.allSatisfy(\.isScheduled)
        #expect(queuedAreScheduled)
        // A new matrix on the same queue picks the schedule up.
        let reopened = try await PricingModelFixtures.matrix(queue: queue)
        #expect(reopened.schedule == scheduled)
    }

    private func decode(_ request: PushRequest?) throws -> SubscriptionPriceCreateRequest {
        let body = try #require(request?.body)
        return try JSONDecoder().decode(SubscriptionPriceCreateRequest.self, from: body)
    }

    @Test func increasesCountTheirSubscribers() async throws {
        let matrix = try await PricingModelFixtures.matrix(strategy: PricingModelFixtures.premiumStrategy, follows: true)

        let consent = matrix.increaseConsent(subscribers: DebugPricingResults.subscribers())

        #expect(consent.items.map(\.territory.alpha2) == ["BM", "KY", "LU", "CH", "NO", "IS", "IL"])
        #expect(consent.subscriberTotal == 105)
        #expect(consent.title == "7 territories go up · 105 existing subscribers")
        let israel = try #require(consent.items.last)
        #expect(israel.pricesText == "₪149.90 → ₪154.90")
        #expect(israel.subscribersText == "24 subscribers")
        #expect(consent.items[1].subscribersText == "1 subscriber")
    }

    @Test func withoutCountsTheWarningOnlyCountsTerritories() async throws {
        let matrix = try await PricingModelFixtures.matrix(strategy: PricingModelFixtures.premiumStrategy, follows: true)
        let consent = matrix.increaseConsent(subscribers: nil)
        #expect(consent.subscriberTotal == nil)
        #expect(consent.title == "7 territories go up")
        #expect(consent.items.allSatisfy { $0.subscribersText == nil })
    }

    @Test func decreasesNeedNoConsent() async throws {
        let matrix = try await PricingModelFixtures.matrix(follows: true)
        #expect(matrix.increaseConsent(subscribers: [:]).isEmpty)
    }
}
#endif
