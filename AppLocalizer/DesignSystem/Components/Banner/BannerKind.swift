//
//  BannerKind.swift
//  AppLocalizer
//

import SwiftUI

/// The system states a `Banner` reports (design handoff, "System states").
enum BannerKind: Sendable {
    /// Neutral: edits stay queued on this Mac.
    case offline
    /// Warning: App Store Connect's hourly quota is used up.
    case rateLimited
    /// Error, with Apple's code and detail text.
    case apiError
    /// Error: some changes in a push failed.
    case partialFailure
    /// Neutral information, e.g. "no sales data".
    case info

    var systemImage: String {
        switch self {
        case .offline: "wifi.slash"
        case .rateLimited: "hourglass"
        case .apiError: "exclamationmark.octagon.fill"
        case .partialFailure: "exclamationmark.triangle.fill"
        case .info: "info.circle"
        }
    }

    var tint: Color {
        switch self {
        case .offline, .info: Palette.label2
        case .rateLimited: Palette.warning
        case .apiError, .partialFailure: Palette.danger
        }
    }

    var background: Color {
        switch self {
        case .offline, .info: Palette.fill1
        case .rateLimited: Palette.warningTint
        case .apiError, .partialFailure: Palette.dangerTint
        }
    }
}
