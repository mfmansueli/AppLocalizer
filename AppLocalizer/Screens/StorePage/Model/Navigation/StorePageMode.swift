//
//  StorePageMode.swift
//  AppLocalizer
//

import Foundation

/// The Store Page's views: Editor and In-App Texts in the header, Coverage
/// from its More menu.
enum StorePageMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case coverage
    case editor
    case inAppTexts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coverage: String(localized: "Coverage")
        case .editor: String(localized: "Editor")
        case .inAppTexts: String(localized: "In-App Texts")
        }
    }
}
