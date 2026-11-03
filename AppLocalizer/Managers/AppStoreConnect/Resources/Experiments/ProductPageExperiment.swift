//
//  ProductPageExperiment.swift
//  AppLocalizer
//

import Foundation

/// A Product Page Optimization test (`appStoreVersionExperiments`, v2):
/// the app's current page is its control, and its treatments share the
/// traffic it gets.
struct ProductPageExperiment: Hashable, Sendable, Identifiable {
    var id: String
    var name: String?
    var platform: String?
    var state: String?
    var trafficProportion: Int?

    init(id: String, name: String? = nil, platform: String? = nil, state: String? = nil, trafficProportion: Int? = nil) {
        self.id = id
        self.name = name
        self.platform = platform
        self.state = state
        self.trafficProportion = trafficProportion
    }

    init(_ resource: ScreenshotAPIResource<ProductPageExperimentAttributes>) {
        self.init(
            id: resource.id, name: resource.attributes?.name, platform: resource.attributes?.platform,
            state: resource.attributes?.state, trafficProportion: resource.attributes?.trafficProportion
        )
    }

    /// States a test is over in. Every other one, a draft included, is in
    /// the way of a new test: App Store Connect runs one at a time and
    /// refuses a second draft (409 `STATE_ERROR`).
    static let finishedStates: Set<String> = ["COMPLETED", "STOPPED"]

    var isFinished: Bool { state.map(Self.finishedStates.contains) ?? false }

    /// "a draft", "in review", "running"…, for "already has a test, …".
    var stateTitle: String {
        switch state {
        case "PREPARE_FOR_SUBMISSION": String(localized: "a draft")
        case "READY_FOR_REVIEW", "WAITING_FOR_REVIEW": String(localized: "waiting for review")
        case "IN_REVIEW": String(localized: "in review")
        case "ACCEPTED": String(localized: "approved, not started")
        case "APPROVED": String(localized: "running")
        case "REJECTED": String(localized: "rejected")
        case "COMPLETED": String(localized: "completed")
        case "STOPPED": String(localized: "stopped")
        default: state ?? String(localized: "in an unknown state")
        }
    }
}
