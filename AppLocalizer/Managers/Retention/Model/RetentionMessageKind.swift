//
//  RetentionMessageKind.swift
//  AppLocalizer
//

import Foundation

/// What a retention message shows under its header and text. When someone
/// is eligible for one of the subscription's retention offers, Apple shows
/// the best offer in place of the image.
enum RetentionMessageKind: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    case message
    case image
    case offer

    var id: String { rawValue }

    /// The editor's Shows control: "Message only", "With image", "With offer".
    var title: String {
        switch self {
        case .message: String(localized: "Message only")
        case .image: String(localized: "With image")
        case .offer: String(localized: "With offer")
        }
    }

    /// Review & Push's summary: "Message and image".
    var summary: String {
        switch self {
        case .message: String(localized: "Message")
        case .image: String(localized: "Message and image")
        case .offer: String(localized: "Message and offer")
        }
    }
}
