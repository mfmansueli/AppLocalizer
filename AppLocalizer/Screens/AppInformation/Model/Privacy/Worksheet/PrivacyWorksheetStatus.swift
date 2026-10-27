//
//  PrivacyWorksheetStatus.swift
//  AppLocalizer
//

import Foundation

/// Where App Privacy stands, for the page's pill, the page column and the
/// overview: Not started → In progress → Done → Marked published, and Out
/// of date when App Store Connect may no longer match.
enum PrivacyWorksheetStatus: Hashable, Sendable {
    case notStarted
    case inProgress
    /// Done here; not in App Store Connect yet.
    case done
    case published(Date)
    /// Marked published on that date, but changed since.
    case outOfDate(Date)

    var title: String {
        switch self {
        case .notStarted: String(localized: "Not started")
        case .inProgress: String(localized: "In progress")
        case .done: String(localized: "Worksheet done · not in App Store Connect yet")
        case let .published(date): String(localized: "Marked published \(date.formatted(date: .abbreviated, time: .omitted))")
        case .outOfDate: String(localized: "Out of date with App Store Connect")
        }
    }

    /// The overview's shorter line.
    var shortTitle: String {
        switch self {
        case .notStarted: String(localized: "Not started")
        case .inProgress: String(localized: "In progress")
        case .done: String(localized: "Done")
        case .published: String(localized: "Published")
        case .outOfDate: String(localized: "Out of date")
        }
    }

    /// The date it was marked published, if it was.
    var publishedDate: Date? {
        switch self {
        case let .published(date), let .outOfDate(date): date
        case .notStarted, .inProgress, .done: nil
        }
    }

    /// Not started and out of date need attention.
    var needsAttention: Bool {
        switch self {
        case .notStarted, .outOfDate: true
        case .inProgress, .done, .published: false
        }
    }
}
