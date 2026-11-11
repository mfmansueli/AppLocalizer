//
//  ProStatus.swift
//  AppLocalizer
//

import Foundation

/// What this person has of AppLocalizer Pro, from their App Store
/// purchases.
enum ProStatus: Hashable, Sendable {
    case free
    /// An active subscription: its plan, when it renews or ends, and
    /// whether it's still in the free trial.
    case subscribed(plan: ProPlan, until: Date?, isTrial: Bool)
    case lifetime

    var isPro: Bool { self != .free }
}
