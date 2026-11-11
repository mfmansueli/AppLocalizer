//
//  PaywallPhase.swift
//  AppLocalizer
//

import Foundation

/// Where the paywall is: choosing a plan, comparing Free and Pro, waiting
/// for the App Store, or done.
enum PaywallPhase: Hashable, Sendable {
    case plans
    case compare
    case buying
    /// Bought, or restored.
    case done
}
