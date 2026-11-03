//
//  ReviewPushViewModel+Extras.swift
//  AppLocalizer
//

import Foundation

/// Autopilot's extras in Review & Push, in the same scope as the
/// screenshots: each app's header, search image and App Previews, their own
/// push, and the Product Page Optimization sheet.
extension ReviewPushViewModel {
    var extras: ExtrasPushController { screenshots.extras }

    var extrasPlans: [ExtrasReviewPlan] {
        switch scope {
        case .thisApp: extras.plans(for: selectedAppID.map { [$0] } ?? [])
        case .allApps: extras.orderedPlans
        }
    }

    var showsExtras: Bool { !extrasPlans.isEmpty }

    /// The extras waiting in scope.
    var visibleExtras: [ExtrasReviewItem] { extrasPlans.flatMap(\.items) }

    /// Discard All's part for the extras.
    func discardVisibleExtras() async {
        await screenshots.discardExtras(visibleExtras)
    }

    func undoExtrasDiscards(_ plan: ExtrasReviewPlan) async {
        await screenshots.undoExtrasDiscards(appIDs: [plan.appID])
    }

    func pushExtras(_ plan: ExtrasReviewPlan) {
        screenshots.pushExtras([plan])
    }

    /// “Test with Product Page Optimization…”.
    func openTest(_ plan: ExtrasReviewPlan, placement: ProductPageTestPlacement) {
        extras.test = screenshots.testModel(for: plan, placement: placement)
    }
}
