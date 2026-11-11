//
//  ProGate.swift
//  AppLocalizer
//

import Foundation
import Observation

/// What every gated button goes through: with Pro, the action runs; in
/// Free, the paywall opens saying what was blocked, and its continue button
/// runs the action once Pro is bought.
@MainActor
@Observable
final class ProGate {
    let entitlements: Entitlements
    /// The paywall while it's open.
    var paywall: PaywallModel?

    @ObservationIgnored private let defaults: UserDefaults?

    /// Free's one app: the first the person opens. Kept, so it's the same
    /// app at the next launch.
    private(set) var freeAppID: String? {
        didSet { defaults?.set(freeAppID, forKey: Self.freeAppKey) }
    }

    static let freeAppKey = "pro.freeAppID"

    init(entitlements: Entitlements, defaults: UserDefaults? = nil) {
        self.entitlements = entitlements
        self.defaults = defaults
        freeAppID = defaults?.string(forKey: Self.freeAppKey)
    }

    /// Whether `appID` may be opened: any app with Pro; in Free the first
    /// one opened, which becomes the free app.
    func mayOpen(appID: String) -> Bool {
        guard isFree else { return true }
        if freeAppID == nil { freeAppID = appID }
        return freeAppID == appID
    }

    var isFree: Bool { !entitlements.isPro }

    func require(_ context: PaywallContext, then action: @escaping () -> Void) {
        if let feature = context.feature, !entitlements.canUse(feature) {
            paywall = PaywallModel(context: context, entitlements: entitlements, onContinue: action)
        } else {
            action()
        }
    }

    /// The toolbar's Pro button: the plans, with no card.
    func showPlans() {
        paywall = PaywallModel(context: .menu, entitlements: entitlements)
    }

    /// The paywall's continue button: closes it, then finishes what the
    /// person started.
    func finish(_ model: PaywallModel, continues: Bool) {
        paywall = nil
        if continues, entitlements.isPro { model.onContinue?() }
    }
}

/// A view outside the main window (a preview, a DEBUG scene) has no gate:
/// there everything runs, as with Pro.
@MainActor
extension ProGate? {
    var isFree: Bool { self?.isFree ?? false }

    func require(_ context: PaywallContext, then action: @escaping () -> Void) {
        if let self { self.require(context, then: action) } else { action() }
    }
}
