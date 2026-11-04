//
//  ArtworkCheckKind.swift
//  AppLocalizer
//

import Foundation

/// What a header or search image check looks at. The content kinds are
/// Apple's rules for these placements ("App Store asset best practices":
/// no specific pricing, discounts, website URLs, copyright symbols,
/// claims that can't be verified, Apple-designated recognitions, other
/// platforms or marketplaces, and no alpha channels or transparency); the
/// rest is advice.
enum ArtworkCheckKind: String, Codable, Hashable, Sendable, CaseIterable {
    case price
    case discount
    case url
    case copyright
    case unverifiableClaim
    case appleRecognition
    case otherPlatform
    case transparency
    case searchHeadlineLength
    case headerTextLength
    case safeArea
    case textContrast
    case edgeContrast
    case sharedLook
    /// A motion loop that isn't 20 seconds at 30 fps, has sound, or jumps
    /// where it repeats.
    case loop
    /// A Claude Design page that's missing what AppLocalizer fills in, or
    /// whose capture didn't load.
    case page

    /// Apple doesn't allow it: an error.
    var isApplesRule: Bool {
        switch self {
        case .price, .discount, .url, .copyright, .unverifiableClaim, .appleRecognition, .otherPlatform, .transparency: true
        default: false
        }
    }

    /// For the pill: "Price", "Safe area".
    var shortReason: String {
        switch self {
        case .price: String(localized: "Price")
        case .discount: String(localized: "Discount")
        case .url: String(localized: "URL")
        case .copyright: String(localized: "©")
        case .unverifiableClaim: String(localized: "Claim")
        case .appleRecognition: String(localized: "Apple recognition")
        case .otherPlatform: String(localized: "Other platform")
        case .transparency: String(localized: "Transparency")
        case .searchHeadlineLength, .headerTextLength: String(localized: "Too long")
        case .safeArea: String(localized: "Safe area")
        case .textContrast, .edgeContrast: String(localized: "Contrast")
        case .sharedLook: String(localized: "Look")
        case .loop: String(localized: "Loop")
        case .page: String(localized: "Page")
        }
    }

    /// "discounts aren’t allowed here", for a content kind.
    var notAllowed: String {
        switch self {
        case .price: String(localized: "prices and currency symbols aren’t allowed here")
        case .discount: String(localized: "discounts and percentages aren’t allowed here")
        case .url: String(localized: "website addresses aren’t allowed here")
        case .copyright: String(localized: "copyright symbols aren’t allowed here")
        case .unverifiableClaim: String(localized: "claims that can’t be verified aren’t allowed here")
        case .appleRecognition: String(localized: "Apple’s recognitions aren’t allowed here; the App Store shows them itself")
        case .otherPlatform: String(localized: "other platforms and stores aren’t allowed here")
        default: String(localized: "this isn’t allowed here")
        }
    }
}
