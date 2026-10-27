//
//  PushFixtures.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Small pending changes for the push and review tests.
enum PushFixtures {
    static func price(_ territory: String, app: StoreApp.ID = "lumen", delta: Int = -50, source: ChangeSource = .suggestion) -> PendingChange {
        PendingChange(
            id: "price.annual.\(territory)",
            appID: app,
            section: .subscriptionPricing,
            group: "Subscription Pricing · Annual",
            groupID: "annual",
            groupNote: "Prices change as soon as Apple processes them",
            title: territory,
            oldValue: "old \(territory)",
            newValue: "new \(territory)",
            deltaPercent: delta,
            source: source,
            requests: [PushRequest(method: .post, path: "/v1/subscriptionPrices/\(territory)")],
            restoreRequests: [PushRequest(method: .post, path: "/v1/subscriptionPrices/\(territory)/restore")]
        )
    }

    static func listing(_ field: String, app: StoreApp.ID = "lumen", new: String = "new", source: ChangeSource = .you) -> PendingChange {
        PendingChange(
            id: "listing.de.\(field)",
            appID: app,
            section: .storePage,
            group: "Store Page · version 1.4",
            title: "German · \(field)",
            oldValue: "old",
            newValue: new,
            source: source,
            requests: [PushRequest(method: .patch, path: "/v1/appStoreVersionLocalizations/de-\(field)")]
        )
    }
}
