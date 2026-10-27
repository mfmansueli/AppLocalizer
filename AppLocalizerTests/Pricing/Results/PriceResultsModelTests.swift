//
//  PriceResultsModelTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Results of Lumen Plus Annual's Oct 26, 2026 push (`DebugPricingResults`).
@MainActor
@Suite("PriceResultsModel")
struct PriceResultsModelTests {
    private let queue = ChangeQueue()

    private func model(services: DebugPricingServices = DebugPricingServices()) throws -> PriceResultsModel {
        try PriceResultsModel(appID: PricingModelFixtures.appID, product: PricingModelFixtures.annual(), services: services, queue: queue)
    }

    private var records: [PushRecord] {
        [DebugPricingResults.annualPush()].compactMap(\.self) + DebugWorkspace.pushRecords
    }

    @Test func noPushMeansNothingToCompare() async throws {
        let results = try model()
        await results.load(records: DebugWorkspace.pushRecords.filter { $0.appID != PricingModelFixtures.appID }, today: .now)
        #expect(results.state == .noChanges)
    }

    @Test func theFirstDayIsTooEarly() async throws {
        let results = try model()
        await results.load(records: records, today: PricingSampleData.pushDate)
        guard case let .tooEarly(changedOn, day, arrivesOn) = results.state else {
            Issue.record("Expected too early, got \(results.state)")
            return
        }
        #expect(PricingText.date(changedOn) == "Oct 26, 2026")
        #expect(day == 1)
        #expect(PricingText.date(arrivesOn) == "Nov 23, 2026")
    }

    @Test func fourWeeksLaterTheTerritoriesCompare() async throws {
        let results = try model()
        await results.load(records: records, today: PricingSampleData.date("2026-11-23"))
        #expect(try results.state == .ready(changedOn: #require(DebugPricingResults.annualPush()).date))
        let summary = try #require(results.summary)
        #expect(summary.countedCount == 17)
        #expect(summary.betterCount == 6)
        #expect(summary.worseCount == 3)
        #expect(summary.startsBefore == 566)
        #expect(summary.startsAfter == 739)
        #expect(results.results.count == 17)
        #expect(results.results.first?.territory.alpha2 == "IN")
        #expect(results.results.map(\.before.pageViews) == results.results.map(\.before.pageViews).sorted(by: >))
    }

    @Test func theLatestPushOfThisProductCounts() async throws {
        let results = try model()
        // Without the Oct 26 push, Jul 14's three territories are the latest.
        await results.load(records: DebugWorkspace.pushRecords, today: PricingSampleData.date("2026-11-23"))
        #expect(results.summary?.territoryCount == 3)
    }

    @Test func aKeyWithoutSalesCantCompare() async throws {
        let results = try model(services: DebugPricingServices(canReadSales: false))
        await results.load(records: records, today: PricingSampleData.date("2026-11-23"))
        guard case .salesUnavailable = results.state else {
            Issue.record("Expected sales unavailable, got \(results.state)")
            return
        }
    }

    @Test func aFailedReadSaysWhy() async throws {
        let results = try model(services: DebugPricingServices(error: .rateLimited))
        await results.load(records: records, today: PricingSampleData.date("2026-11-23"))
        guard case .failed = results.state else {
            Issue.record("Expected failure, got \(results.state)")
            return
        }
    }

    @Test func restoreQueuesTheOldPriceForReview() async throws {
        let results = try model()
        await results.load(records: records, today: PricingSampleData.date("2026-11-23"))
        let japan = try #require(results.results.first { $0.territory.alpha2 == "JP" })
        let brazil = try #require(results.results.first { $0.territory.alpha2 == "BR" })
        #expect(results.canRestore(japan))
        #expect(!results.canRestore(brazil))
        #expect(!results.isRestoreQueued("JPN"))

        results.restore("JPN")

        let change = try #require(queue.change(id: "price.\(DebugPricingCatalog.lumenAnnualID).JPN"))
        #expect(change.source == .restore)
        #expect(change.oldValue == "¥4,800")
        #expect(change.newValue == "¥6,000")
        #expect(change.groupNote == PriceSchedule.immediate.note)
        #expect(results.isRestoreQueued("JPN"))
        #expect(queue.changes.count == 1)
    }
}
#endif
