//
//  StoreAppearance.swift
//  AppLocalizer
//

import SwiftUI

/// The preview's Light · Dark switch: the App Store in either appearance,
/// whatever the app's.
enum StoreAppearance: String, CaseIterable, Hashable, Sendable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: String(localized: "Light")
        case .dark: String(localized: "Dark")
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }
}
