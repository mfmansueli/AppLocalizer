//
//  StorePageVersionTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The version picker's list, the version the Store Page opens on, and the
/// "No version to edit" state's suggested next version.
@Suite("StorePageVersion")
struct StorePageVersionTests {
    private func version(_ id: String, _ state: ListingVersionState, daysAgo: Double) -> StorePageVersion {
        StorePageVersion(
            id: id,
            listingVersion: ListingVersion(id, state: state),
            platform: "IOS",
            createdDate: Date(timeIntervalSinceReferenceDate: 800_000_000 - daysAgo * 86400)
        )
    }

    @Test func thePickerListsNewestFirstWithOneLiveVersion() {
        let versions = [
            version("1.2", .readyForDistribution, daysAgo: 200),
            version("1.4", .prepareForSubmission, daysAgo: 1),
            version("1.3", .readyForDistribution, daysAgo: 60),
        ]
        #expect(StorePageVersion.pickerVersions(from: versions).map(\.id) == ["1.4", "1.3"])
    }

    @Test func theNewestEditableVersionIsPreferred() {
        let versions = [
            version("1.5", .waitingForReview, daysAgo: 1),
            version("1.4", .metadataRejected, daysAgo: 10),
            version("1.3", .readyForDistribution, daysAgo: 60),
        ]
        #expect(StorePageVersion.preferred(in: versions)?.id == "1.4")
    }

    @Test func withoutAnEditableVersionTheLiveOneIsPreferred() {
        let versions = [version("1.5", .inReview, daysAgo: 1), version("1.3", .readyForDistribution, daysAgo: 60)]
        #expect(StorePageVersion.preferred(in: versions)?.id == "1.3")
        #expect(StorePageVersion.preferred(in: [version("1.5", .inReview, daysAgo: 1)])?.id == "1.5")
        #expect(StorePageVersion.preferred(in: []) == nil)
    }

    @Test(arguments: [("1.3", "1.4"), ("2.0.9", "2.0.10"), ("7", "8"), ("1.0b", "1.0b")])
    func theNextVersionBumpsTheLastNumber(current: String, next: String) {
        #expect(NoVersionView.nextVersion(after: current) == next)
    }

    @Test func appStoreConnectOpensOnTheAppsDistributionPage() {
        #expect(NoVersionView.appStoreConnectURL(appID: "6450000001").absoluteString == "https://appstoreconnect.apple.com/apps/6450000001/distribution")
    }
}
