//
//  ProPurchaseOutcome.swift
//  AppLocalizer
//

import Foundation

/// How a purchase of AppLocalizer Pro ended.
enum ProPurchaseOutcome: Hashable, Sendable {
    case purchased(ProStatus)
    /// The person closed the App Store's sheet.
    case cancelled
    /// Waiting for approval (Ask to Buy) or a bank: Pro starts by itself
    /// when it comes through.
    case pending
    case failed(String)
}
