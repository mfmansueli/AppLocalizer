//
//  AppInformationTestSupport.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Shared fixtures for App Information's tests: a builder for one app and
/// version, and readers for the JSON a request sends.
enum AppInformationTestSupport {
    static let appID = "6450000001"
    static let app = StoreApp(id: appID, name: "Lumen Journal", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")

    static let ids = AppInformationResourceIDs(
        appID: appID,
        appInfoID: "info-1",
        ageRatingDeclarationID: "age-1",
        versionID: "v14",
        reviewDetailID: "review-1"
    )

    static let builder = AppInformationChangeBuilder(appID: appID, ids: ids, versionString: "1.4")

    /// The request's body as a JSON object.
    static func json(_ request: PushRequest?) -> [String: Any] {
        guard let body = request?.body, let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { return [:] }
        return object
    }

    /// `data.attributes` of the request's body.
    static func attributes(_ request: PushRequest?) -> [String: Any] {
        (json(request)["data"] as? [String: Any])?["attributes"] as? [String: Any] ?? [:]
    }

    /// `data.relationships.<name>.data.id`, or nil for a cleared relationship.
    static func relationshipID(_ request: PushRequest?, _ name: String) -> String? {
        let relationships = (json(request)["data"] as? [String: Any])?["relationships"] as? [String: Any]
        let relationship = relationships?[name] as? [String: Any]
        return (relationship?["data"] as? [String: Any])?["id"] as? String
    }

    /// The card for `family` with the given declarations.
    static func card(
        _ family: DeviceFamily = .iPhone,
        published: Set<AccessibilityFeature>? = nil,
        draft: Set<AccessibilityFeature>? = nil,
        isLive: Bool = true
    ) -> AccessibilityCard {
        AccessibilityCard(
            family: family,
            published: published.map { AccessibilityAnswer(features: $0) },
            draft: draft.map { AccessibilityAnswer(features: $0) },
            draftID: draft == nil ? nil : "draft-\(family.rawValue)",
            isLive: isLive,
            upcomingVersion: "1.4"
        )
    }
}
