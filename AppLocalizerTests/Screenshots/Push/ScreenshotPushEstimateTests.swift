//
//  ScreenshotPushEstimateTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Review's footer estimate for images: four requests per image, one per
/// live screenshot deleted and one per set.
@MainActor
@Suite("PushCostEstimate+Review")
struct ScreenshotPushEstimateTests {
    private typealias Fixtures = ScreenshotPushTestFixtures

    @Test func fortyNewImagesInEightSetsAreAbout168Requests() {
        let plan = ScreenshotPushPlanner().plan(Fixtures.input())
        let estimate = PushCostEstimate(groups: plan.groups)
        #expect(estimate.requests == 168)
        #expect(estimate.reviewText() == "About 168 requests · 2 min · 5% of the hourly limit")
    }

    @Test func replacedScreenshotsAndOtherChangesAddUp() {
        let group = Fixtures.group(.german, live: Fixtures.liveSet(.german, count: 3), slots: [0, 1])
        let estimate = PushCostEstimate(groups: [group])
        #expect(estimate.requests == 2 * 4 + 2 + 1)
        #expect(estimate.reviewText(otherRequests: 9) == "About 20 requests · 1 min · 1% of the hourly limit")
    }

    @Test func onlyIncludedImagesCount() {
        let group = Fixtures.group(.arabic, live: nil, slots: [0, 1, 2])
        let first = group.items[0].id
        #expect(PushCostEstimate(groups: [group]) { $0.id == first }.requests == 5)
        #expect(PushCostEstimate(groups: [group]) { _ in false }.requests == 0)
    }
}
#endif
