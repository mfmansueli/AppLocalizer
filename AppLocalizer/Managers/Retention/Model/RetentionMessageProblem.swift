//
//  RetentionMessageProblem.swift
//  AppLocalizer
//

import Foundation

/// Why a retention message can't be pushed yet. Review & Push shows the
/// first one and skips the change until it's fixed.
enum RetentionMessageProblem: Hashable, Sendable {
    case noName
    case nameTooLong
    case nameTaken
    case noSubscriptions
    case noSourceText(language: String)
    case incomplete(languages: [String])
    case tooLong(languages: [String])
    case noImage
    case imageDoesNotFit(String)
    case noOffers
    case withApple
    case tooManyMessages

    var message: String {
        switch self {
        case .noName:
            String(localized: "Name the message.")
        case .nameTooLong:
            String(localized: "The name is longer than \(RetentionLimits.referenceNameLength) characters.")
        case .nameTaken:
            String(localized: "Another message has this name. Give this one its own.")
        case .noSubscriptions:
            String(localized: "Choose the subscriptions that show it.")
        case let .noSourceText(language):
            String(localized: "Write the header and message in \(language) first.")
        case let .incomplete(languages):
            String(localized: "\(languages.formatted(.list(type: .and))) needs both a header and a message.")
        case let .tooLong(languages):
            String(localized: """
            \(languages.formatted(.list(type: .and))) runs over \(RetentionLimits.headerLength) or \
            \(RetentionLimits.bodyLength) characters.
            """)
        case .noImage:
            String(localized: "Choose an image, or show the message only.")
        case let .imageDoesNotFit(reason):
            String(localized: "The image doesn’t fit: \(reason)")
        case .noOffers:
            String(localized: "Add a retention offer for these subscriptions, or show the message only.")
        case .withApple:
            String(localized: "Apple is reviewing this message; change it once the review ends.")
        case .tooManyMessages:
            String(localized: "An app can have \(RetentionLimits.messagesPerApp) retention messages.")
        }
    }
}
