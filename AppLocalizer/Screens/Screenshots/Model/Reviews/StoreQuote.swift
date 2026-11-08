//
//  StoreQuote.swift
//  AppLocalizer
//

import Foundation

/// One real 5-star App Store review a Reviews slot shows: what was written
/// and the reviewer's name, as the App Store lists them. Nothing here is
/// written for the person.
struct StoreQuote: Hashable, Sendable, Codable {
    var text: String
    var name: String
    /// The country (ISO 3166, uppercase) whose storefront it was written in.
    var country: String
    /// Taken from the primary language's storefront because this one has
    /// fewer than three; the person approves it before push.
    var isBorrowed = false
}
