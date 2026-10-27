//
//  LocaleScopeRow.swift
//  AppLocalizer
//

import Foundation

/// One locale in the Locale Scope sheet: whether it's in, how many
/// captions it has, whether its captures show its own interface, and what's
/// live there now.
struct LocaleScopeRow: Identifiable, Hashable, Sendable {
    var locale: StoreLocale
    var isIncluded: Bool
    var isPrimary: Bool
    var isPinned: Bool
    var captionCount: Int
    var slotCount: Int
    var hasOwnInterface: Bool
    var live: Live

    var id: String { locale.code }

    enum Live: Hashable, Sendable {
        case localizedSet
        case uploadedByHand
        case usesPrimary
    }

    /// "5 of 5", "2 of 5", "None yet".
    var captionsTitle: String {
        captionCount == 0 ? String(localized: "None yet") : String(localized: "\(captionCount) of \(slotCount)")
    }

    var capturesTitle: String {
        hasOwnInterface ? String(localized: "Own interface") : String(localized: "English interface")
    }

    func liveTitle(primaryName: String) -> String {
        switch live {
        case .localizedSet: String(localized: "Localized set")
        case .uploadedByHand: String(localized: "Uploaded by hand")
        case .usesPrimary: String(localized: "Uses \(primaryName)")
        }
    }
}
