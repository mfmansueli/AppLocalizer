//
//  StrategyInspectorTab.swift
//  AppLocalizer
//

import Foundation

/// The strategy inspector's two tabs: the whole strategy, or the selected territory.
enum StrategyInspectorTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case strategy
    case territory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strategy: String(localized: "Strategy")
        case .territory: String(localized: "Territory")
        }
    }
}
