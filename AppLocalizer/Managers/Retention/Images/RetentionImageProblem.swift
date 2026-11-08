//
//  RetentionImageProblem.swift
//  AppLocalizer
//

import Foundation

/// Why an image can't go on a retention message.
enum RetentionImageProblem: Hashable, Sendable {
    case notPNG
    case wrongWidth(Int)
    case wrongHeight(Int)
    case transparency
    case unreadable

    var message: String {
        switch self {
        case .notPNG:
            String(localized: "It isn’t a PNG.")
        case let .wrongWidth(width):
            String(localized: "It’s \(width) pixels wide; Apple wants \(RetentionLimits.imageWidth).")
        case let .wrongHeight(height):
            String(localized: """
            It’s \(height) pixels tall; Apple wants \(RetentionLimits.imageHeights.lowerBound) to \
            \(RetentionLimits.imageHeights.upperBound).
            """)
        case .transparency:
            String(localized: "It has transparency, which Apple doesn’t take.")
        case .unreadable:
            String(localized: "AppLocalizer couldn’t read it as an image.")
        }
    }
}
