//
//  PriceChangeStatus.swift
//  AppLocalizer
//

import Foundation

/// The Status column's badge.
enum PriceChangeStatus: String, CaseIterable, Hashable, Sendable {
    case unchanged
    case increase
    case decrease
    case recommended
    case editedManually
    case custom
    case scheduled
    case excluded

    var title: String {
        switch self {
        case .unchanged: "Unchanged"
        case .increase: "Increase"
        case .decrease: "Decrease"
        case .recommended: "Recommended"
        case .editedManually: "Edited manually"
        case .custom: "Custom"
        case .scheduled: "Scheduled"
        case .excluded: "Excluded"
        }
    }

    /// SF Symbol for the badge; nil for plain text.
    var systemImage: String? {
        switch self {
        case .unchanged: nil
        case .increase: "arrowtriangle.up.fill"
        case .decrease: "arrowtriangle.down.fill"
        case .recommended: "lightbulb"
        case .editedManually: "pencil"
        case .custom: "slider.horizontal.3"
        case .scheduled: "calendar"
        case .excluded: "nosign"
        }
    }

    /// The prototype's rule: an unchanged row is Excluded or Unchanged; a
    /// changed one is Scheduled when the push has a date, otherwise named by
    /// who proposed it. Without an origin (e.g. a price changed in App Store
    /// Connect) it's an Increase or Decrease.
    static func resolve(
        change: PriceChange?,
        origin: PriceChangeOrigin?,
        isExcluded: Bool = false,
        isScheduled: Bool = false
    ) -> PriceChangeStatus {
        guard let change, change.isChanged else { return isExcluded ? .excluded : .unchanged }
        if isScheduled { return .scheduled }
        switch origin {
        case .manual: return .editedManually
        case .custom: return .custom
        case .recommended: return .recommended
        case nil: return change.direction == .increase ? .increase : .decrease
        }
    }
}
