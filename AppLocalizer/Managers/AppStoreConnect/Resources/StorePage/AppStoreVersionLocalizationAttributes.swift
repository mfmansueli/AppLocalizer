//
//  AppStoreVersionLocalizationAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appStoreVersionLocalizations` resource: one locale's version-level
/// texts. Fields never filled come back as null.
struct AppStoreVersionLocalizationAttributes: Decodable, Sendable {
    var locale: String
    var description: String?
    var keywords: String?
    var marketingUrl: String?
    var promotionalText: String?
    var supportUrl: String?
    var whatsNew: String?

    /// The texts by listing field, empty ones left out.
    var texts: [ListingField: String] {
        let values: [ListingField: String?] = [
            .description: description,
            .keywords: keywords,
            .marketingURL: marketingUrl,
            .promotionalText: promotionalText,
            .supportURL: supportUrl,
            .whatsNew: whatsNew,
        ]
        return values.compactMapValues { $0?.isEmpty == false ? $0 : nil }
    }
}
