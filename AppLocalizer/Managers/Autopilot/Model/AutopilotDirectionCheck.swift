//
//  AutopilotDirectionCheck.swift
//  AppLocalizer
//

import Foundation

/// A language check on a direction: "German: 1 caption too long, will be
/// shortened", "Fits all 12 languages", "Arabic mirrors", "Japanese fits".
struct AutopilotDirectionCheck: Codable, Hashable, Sendable {
    enum Kind: String, Codable, Hashable, Sendable {
        case tooLong
        case fitsAll
        case mirrors
        case fits
    }

    var kind: Kind
    var locale: String?
    var count: Int

    var title: String {
        let language = locale.flatMap { StoreLocaleCatalog.locale(code: $0)?.shortName } ?? locale ?? ""
        return switch kind {
        case .tooLong:
            if count == 1 {
                String(localized: "\(language): 1 caption too long, will be shortened")
            } else {
                String(localized: "\(language): \(count) captions too long, will be shortened")
            }
        case .fitsAll: String(localized: "Fits all \(count) languages")
        case .mirrors: String(localized: "\(language) mirrors")
        case .fits: String(localized: "\(language) fits")
        }
    }

    var style: PillStyle {
        kind == .tooLong ? .warning : .neutral
    }
}
