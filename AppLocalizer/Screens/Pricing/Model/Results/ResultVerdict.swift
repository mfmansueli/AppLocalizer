//
//  ResultVerdict.swift
//  AppLocalizer
//

import Foundation

/// How a changed territory did, in plain words. Results compare; they don't
/// prove a price caused anything.
enum ResultVerdict: String, CaseIterable, Hashable, Sendable {
    /// More starts and at least the same proceeds.
    case better
    /// More starts, less proceeds: neutral.
    case moreStartsLessProceeds
    /// No more starts. Offers Restore, which queues the old price for review.
    case worse
    /// Fewer than 10 starts on both sides.
    case tooLittleData

    var title: String {
        switch self {
        case .better: String(localized: "Better")
        case .moreStartsLessProceeds: String(localized: "More starts, less proceeds")
        case .worse: String(localized: "Worse")
        case .tooLittleData: String(localized: "Too little data")
        }
    }

    var offersRestore: Bool { self == .worse }

    /// Whether the territory counts toward the summary.
    var hasEnoughData: Bool { self != .tooLittleData }
}
