//
//  SuggestionFieldKey.swift
//  AppLocalizer
//

import Foundation

/// One app's field, for what's kept per field (provenance).
struct SuggestionFieldKey: Hashable, Codable, Sendable {
    var appID: StoreApp.ID
    var target: SuggestionTarget
}
