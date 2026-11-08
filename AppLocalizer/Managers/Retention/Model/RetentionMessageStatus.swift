//
//  RetentionMessageStatus.swift
//  AppLocalizer
//

import Foundation

/// A message's pill in the list and the editor: a Draft, waiting In Review
/// & Push, In Review at Apple, Live once App Review approved it, or
/// Rejected.
enum RetentionMessageStatus: Hashable, Sendable {
    case draft
    case queued
    case inReview
    case live
    case rejected

    var title: String {
        switch self {
        case .draft: String(localized: "Draft")
        case .queued: String(localized: "In Review & Push")
        case .inReview: String(localized: "In Review")
        case .live: String(localized: "Live")
        case .rejected: String(localized: "Rejected")
        }
    }

    var pillStyle: PillStyle {
        switch self {
        case .draft: .neutral
        case .queued: .accent
        case .inReview: .warning
        case .live: .machineTranslated
        case .rejected: .danger
        }
    }

    /// What VoiceOver and the tooltip add: "Approved by App Review".
    var help: String {
        switch self {
        case .draft: String(localized: "Not sent to Apple yet")
        case .queued: String(localized: "Waiting in Review & Push")
        case .inReview: String(localized: "Waiting for App Review")
        case .live: String(localized: "Approved by App Review; subscribers see it")
        case .rejected: String(localized: "Rejected by App Review; change it and push again")
        }
    }
}
