//
//  TranslationTone.swift
//  AppLocalizer
//

import Foundation

/// The tone AI translators are asked for. Apple Translation ignores it.
enum TranslationTone: String, CaseIterable, Identifiable, Hashable, Sendable, Codable {
    case warmAndSimple
    case neutral
    case playful
    case professional

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warmAndSimple: String(localized: "Warm and simple")
        case .neutral: String(localized: "Neutral")
        case .playful: String(localized: "Playful")
        case .professional: String(localized: "Professional")
        }
    }

    /// For prompts: "keep the tone warm and simple".
    var promptPhrase: String {
        switch self {
        case .warmAndSimple: "warm and simple"
        case .neutral: "neutral"
        case .playful: "playful"
        case .professional: "professional"
        }
    }
}
