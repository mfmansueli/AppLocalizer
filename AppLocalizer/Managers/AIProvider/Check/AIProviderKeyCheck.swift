//
//  AIProviderKeyCheck.swift
//  AppLocalizer
//

import Foundation

/// What a passing key check found: the vendor took the key, and how fast it
/// answered.
struct AIProviderKeyCheck: Hashable, Sendable {
    var vendor: AIProviderVendor
    /// The round trip of the check.
    var milliseconds: Int
    var date: Date
}
