//
//  StorePageMode.swift
//  AppLocalizer
//

import Foundation

/// The Store Page's views, picked in the context bar.
enum StorePageMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case coverage
    case editor
    case inAppTexts
    case screenshots

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coverage: String(localized: "Coverage")
        case .editor: String(localized: "Editor")
        case .inAppTexts: String(localized: "In-App Texts")
        case .screenshots: String(localized: "Screenshots")
        }
    }
}
