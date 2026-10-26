//
//  GeneralChangeTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// General's changes: categories through the app info's relationships,
/// content rights on the app, copyright and release on the version.
@Suite("App Information changes · General")
struct GeneralChangeTests {
    private typealias Support = AppInformationTestSupport
    private let builder = Support.builder

    @Test func aCategoryIsARelationshipOfTheAppInfo() throws {
        let change = try #require(builder.categoryChange("primaryCategory", from: "LIFESTYLE", to: "HEALTH_AND_FITNESS"))
        #expect(change.id == "appInformation.\(Support.appID).general.primaryCategory")
        #expect(change.group == "App Information · General")
        #expect(change.oldValue == "Lifestyle")
        #expect(change.newValue == "Health & Fitness")
        #expect(change.requests.first?.method == .patch)
        #expect(change.requests.first?.path == "/v1/appInfos/info-1")
        #expect(Support.relationshipID(change.requests.first, "primaryCategory") == "HEALTH_AND_FITNESS")
        #expect(Support.relationshipID(change.restoreRequests.first, "primaryCategory") == "LIFESTYLE")
        #expect(change.conflictCheck?.path == "/v1/appInfos/info-1/relationships/primaryCategory")
        #expect(change.conflictCheck?.keyPath == ["data", "id"])
        #expect(change.conflictCheck?.expected == "LIFESTYLE")
        #expect(builder.categoryChange("primaryCategory", from: "LIFESTYLE", to: "LIFESTYLE") == nil)
    }

    @Test func clearingTheSecondaryCategorySendsNullAndThePrimaryCantBeCleared() throws {
        let secondary = try #require(builder.categoryChange("secondaryCategory", from: "HEALTH_AND_FITNESS", to: nil))
        let data = (Support.json(secondary.requests.first)["data"] as? [String: Any])?["relationships"] as? [String: Any]
        let relationship = data?["secondaryCategory"] as? [String: Any]
        #expect(relationship?["data"] is NSNull)
        #expect(secondary.blockedReason == nil)
        #expect(builder.categoryChange("primaryCategory", from: "LIFESTYLE", to: nil)?.blockedReason != nil)
    }

    @Test func thirdPartyContentWaitsForTheRightsConfirmation() throws {
        let blocked = try #require(builder.contentRightsChange(from: .doesNotUseThirdPartyContent, to: .usesThirdPartyContent, rightsConfirmed: false))
        #expect(blocked.blockedReason != nil)
        let confirmed = try #require(builder.contentRightsChange(from: .doesNotUseThirdPartyContent, to: .usesThirdPartyContent, rightsConfirmed: true))
        #expect(confirmed.blockedReason == nil)
        #expect(confirmed.requests.first?.path == "/v1/apps/\(Support.appID)")
        #expect(Support.attributes(confirmed.requests.first)["contentRightsDeclaration"] as? String == "USES_THIRD_PARTY_CONTENT")
        #expect(Support.attributes(confirmed.restoreRequests.first)["contentRightsDeclaration"] as? String == "DOES_NOT_USE_THIRD_PARTY_CONTENT")
        #expect(confirmed.conflictCheck?.expected == "DOES_NOT_USE_THIRD_PARTY_CONTENT")
    }

    @Test func copyrightIsPerVersion() throws {
        let change = try #require(builder.copyrightChange(from: "© 2025 Northpier", to: "© 2026 Northpier"))
        #expect(change.id == "appInformation.\(Support.appID).general.v14.copyright")
        #expect(change.title == "Copyright · 1.4")
        #expect(change.requests.first?.path == "/v1/appStoreVersions/v14")
        #expect(Support.attributes(change.requests.first)["copyright"] as? String == "© 2026 Northpier")
        #expect(Support.attributes(change.restoreRequests.first)["copyright"] as? String == "© 2025 Northpier")
        #expect(change.conflictCheck?.keyPath == ["data", "attributes", "copyright"])

        let noVersion = AppInformationChangeBuilder(
            appID: Support.appID,
            ids: AppInformationResourceIDs(appID: Support.appID, appInfoID: "info-1"),
            versionString: nil
        )
        #expect(noVersion.copyrightChange(from: "", to: "© 2026") == nil)
    }

    @Test func aScheduledReleaseSendsADateOnTheHour() throws {
        let date = try Date("2026-11-02T10:42:00Z", strategy: .iso8601)
        let change = try #require(builder.releaseChange(from: (.manual, nil), to: (.scheduled, date)))
        let attributes = Support.attributes(change.requests.first)
        #expect(attributes["releaseType"] as? String == "SCHEDULED")
        let sent = try #require(attributes["earliestReleaseDate"] as? String)
        #expect(try Date(sent, strategy: .iso8601) == Date("2026-11-02T10:00:00Z", strategy: .iso8601))
        #expect(Support.attributes(change.restoreRequests.first)["releaseType"] as? String == "MANUAL")
        #expect(builder.releaseChange(from: (.manual, nil), to: (.scheduled, nil))?.blockedReason != nil)
    }

    @Test func queuedValuesAreReadBackOverAppStoreConnects() throws {
        let values = GeneralValues(primaryCategory: "LIFESTYLE", copyright: "© 2025 Northpier")
        let changes = try [
            #require(builder.categoryChange("primaryCategory", from: "LIFESTYLE", to: "BOOKS")),
            #require(builder.copyrightChange(from: "© 2025 Northpier", to: "© 2026 Northpier")),
        ]
        let shown = builder.general(values, with: changes)
        #expect(shown.primaryCategory == "BOOKS")
        #expect(shown.copyright == "© 2026 Northpier")
    }
}
