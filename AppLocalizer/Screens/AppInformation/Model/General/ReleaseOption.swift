//
//  ReleaseOption.swift
//  AppLocalizer
//

import Foundation

/// How a version is released once App Review approves it (`releaseType`).
enum ReleaseOption: String, CaseIterable, Identifiable, Hashable, Sendable {
    case manual = "MANUAL"
    case afterApproval = "AFTER_APPROVAL"
    case scheduled = "SCHEDULED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual: String(localized: "Manually")
        case .afterApproval: String(localized: "Automatically after approval")
        case .scheduled: String(localized: "On a date")
        }
    }
}
