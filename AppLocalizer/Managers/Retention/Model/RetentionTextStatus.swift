//
//  RetentionTextStatus.swift
//  AppLocalizer
//

import Foundation

/// A language's row in Every language: Written (the source language, or
/// text the person typed), Translated, Too long, or Missing.
enum RetentionTextStatus: Hashable, Sendable {
    case written
    case translated
    case tooLong
    case missing

    /// The status of `text` in a language; `isSource` is the language the
    /// others are translated from.
    static func of(_ text: RetentionText?, isSource: Bool) -> RetentionTextStatus {
        guard let text, !text.isEmpty else { return .missing }
        if text.isTooLong { return .tooLong }
        if isSource { return .written }
        switch text.origin {
        case .written: return .written
        case .translated, .assistant: return .translated
        }
    }

    var title: String {
        switch self {
        case .written: String(localized: "Written")
        case .translated: String(localized: "Translated")
        case .tooLong: String(localized: "Too long")
        case .missing: String(localized: "Missing")
        }
    }

    var pillStyle: PillStyle {
        switch self {
        case .written: .neutral
        case .translated: .machineTranslated
        case .tooLong: .warning
        case .missing: .outline
        }
    }

    /// Ready to push: written or translated, within the limits.
    var isReady: Bool {
        self == .written || self == .translated
    }
}
