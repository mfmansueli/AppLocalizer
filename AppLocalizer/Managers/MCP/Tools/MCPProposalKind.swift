//
//  MCPProposalKind.swift
//  AppLocalizer
//

import Foundation

/// What assistants may propose, each a switch in Settings → AI Assistants.
/// Reading is always allowed while the server runs.
enum MCPProposalKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case screenshots
    case storeText
    case prices
    case appInformation

    var id: Self { self }

    var title: String {
        switch self {
        case .screenshots: String(localized: "Propose screenshot templates and captions")
        case .storeText: String(localized: "Propose store text")
        case .prices: String(localized: "Propose prices")
        case .appInformation: String(localized: "Propose app information")
        }
    }

    var caption: String {
        switch self {
        case .screenshots: String(localized: "Template revisions and captions arrive as proposals you accept or reject.")
        case .storeText: String(localized: "Listing text, translations, keywords and What’s New.")
        case .prices: String(localized: "Always refused for apps set to Keep my prices.")
        case .appInformation: String(localized: "Age rating, App Privacy, App Review and export compliance answers.")
        }
    }

    /// The refusal an assistant gets while the switch is off.
    var refusal: String {
        switch self {
        case .screenshots:
            String(localized: "Proposing screenshots is turned off. The person can turn it on in AppLocalizer → Settings → AI Assistants.")
        case .storeText:
            String(localized: "Proposing store text is turned off. The person can turn it on in AppLocalizer → Settings → AI Assistants.")
        case .prices:
            String(localized: "Proposing prices is turned off. The person can turn it on in AppLocalizer → Settings → AI Assistants.")
        case .appInformation:
            String(localized: "Proposing app information is turned off. The person can turn it on in AppLocalizer → Settings → AI Assistants.")
        }
    }
}
