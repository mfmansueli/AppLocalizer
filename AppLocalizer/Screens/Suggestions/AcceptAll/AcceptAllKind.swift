//
//  AcceptAllKind.swift
//  AppLocalizer
//

import Foundation

/// What Accept All goes through: Store Page and screenshot suggestions by
/// language, App Information's by page. Each kind words the sheet and its
/// toasts.
enum AcceptAllKind: Hashable, Sendable {
    case storePage
    case screenshots
    case appInformation

    var title: String {
        switch self {
        case .storePage: String(localized: "Accept Store Page suggestions in every language")
        case .screenshots: String(localized: "Accept screenshot captions in every language")
        case .appInformation: String(localized: "Accept suggestions on every App Information page")
        }
    }

    /// The left column's heading.
    var groupsTitle: String {
        self == .appInformation ? String(localized: "Pages") : String(localized: "Languages")
    }

    /// "32 Store Page suggestions in 6 languages".
    func countText(_ count: Int, groups: Int) -> String {
        let unit = unit(groups)
        switch self {
        case .storePage: return String(localized: "\(count) Store Page suggestions in \(groups) \(unit)")
        case .screenshots: return String(localized: "\(count) screenshot caption suggestions in \(groups) \(unit)")
        case .appInformation: return String(localized: "\(count) App Information suggestions on \(groups) \(unit)")
        }
    }

    /// "languages" or "pages", for `count` of them.
    func unit(_ count: Int) -> String {
        if self == .appInformation {
            return count == 1 ? String(localized: "page") : String(localized: "pages")
        }
        return count == 1 ? String(localized: "language") : String(localized: "languages")
    }

    /// The footer's checkbox.
    var dontAskTitle: String {
        self == .appInformation
            ? String(localized: "Don’t ask again: Accept All accepts every page right away")
            : String(localized: "Don’t ask again: Accept All Languages accepts every language right away")
    }

    /// Added to the toast after turning that on.
    var nextTimeText: String {
        self == .appInformation
            ? String(localized: "Next time, Accept All won’t ask first.")
            : String(localized: "Next time, Accept All Languages won’t ask first.")
    }

    /// The toast after accepting from the sheet, or right away.
    func acceptedText(_ count: Int, groups: Int, withoutAsking: Bool = false, turnedOffAsking: Bool = false) -> String {
        let unit = unit(groups)
        let what = count == 1
            ? String(localized: "Accepted 1 suggestion in \(groups) \(unit)")
            : String(localized: "Accepted \(count) suggestions in \(groups) \(unit)")
        let text = withoutAsking
            ? String(localized: "\(what), without asking. They’re in Review & Push.")
            : String(localized: "\(what). They’re in Review & Push.")
        return turnedOffAsking ? "\(text) \(nextTimeText)" : text
    }
}
