//
//  RetentionMCPJSON.swift
//  AppLocalizer
//

import Foundation

/// Retention messages, offers and subscriptions as the retention tools
/// return them.
@MainActor
enum RetentionMCPJSON {
    static func limits() -> JSONValue {
        [
            "header": .int(RetentionLimits.headerLength),
            "body": .int(RetentionLimits.bodyLength),
            "referenceName": .int(RetentionLimits.referenceNameLength),
            "messagesPerApp": .int(RetentionLimits.messagesPerApp),
            "offersPerSubscription": .int(RetentionLimits.offersPerSubscription),
            "image": .string(String(localized: """
            PNG, \(RetentionLimits.imageWidth) pixels wide and \(RetentionLimits.imageHeights.lowerBound) to \
            \(RetentionLimits.imageHeights.upperBound) tall, no transparency; it shows in light and dark mode.
            """)),
        ]
    }

    static func subscription(_ subscription: RetentionSubscription, in context: RetentionMCPContext) -> JSONValue {
        var json: [String: JSONValue] = [
            "id": .string(subscription.id),
            "productId": .string(subscription.productID),
            "name": .string(subscription.name),
            "group": .string(subscription.groupName),
        ]
        if let period = subscription.period { json["duration"] = .string(period.rawValue) }
        if let price = subscription.basePrice { json["usPrice"] = MCPPriceValue.json(price) }
        if let message = context.messages.first(where: { $0.subscriptionIDs.contains(subscription.id) }) {
            json["messageId"] = .string(message.id)
        }
        return .object(json)
    }

    static func message(_ message: RetentionMessage, in context: RetentionMCPContext) -> JSONValue {
        let builder = context.builder()
        var json: [String: JSONValue] = [
            "id": .string(message.id),
            "referenceName": .string(message.referenceName),
            "status": .string(context.status(of: message)),
            "kind": .string(message.kind.rawValue),
            "subscriptions": .array(message.subscriptionIDs.map { .string($0) }),
            "isNew": .bool(message.isNew),
        ]
        var texts: [String: JSONValue] = [:]
        for locale in builder.languages(of: message) {
            let text = message.text(for: locale.code)
            guard !text.isEmpty else { continue }
            texts[locale.code] = [
                "header": .string(text.header),
                "body": .string(text.body),
                "headerLength": .int(text.headerCount),
                "bodyLength": .int(text.bodyCount),
                "tooLong": .bool(text.isTooLong),
            ]
        }
        json["texts"] = .object(texts)
        let missing = builder.languages(of: message).filter { !message.text(for: $0.code).isComplete }.map(\.code)
        if !missing.isEmpty { json["missingLanguages"] = .array(missing.map { .string($0) }) }
        if let image = message.image { json["image"] = Self.image(image) }
        if let state = message.remote?.versionState { json["versionState"] = .string(state.rawValue) }
        let problems = builder.problems(for: message, messageCount: context.messages.count)
        if !problems.isEmpty { json["problems"] = .array(problems.map { .string($0.message) }) }
        return .object(json)
    }

    static func image(_ image: RetentionImage) -> JSONValue {
        var json: [String: JSONValue] = [
            "name": .string(image.name),
            "width": .int(image.pixelWidth),
            "height": .int(image.pixelHeight),
            "fits": .bool(image.fits),
        ]
        if let assetID = image.assetID { json["assetId"] = .string(assetID) }
        if image.assetID == nil { json["uploadedWhenPushed"] = true }
        if !image.problems.isEmpty { json["problems"] = .array(image.problems.map { .string($0.message) }) }
        return .object(json)
    }

    static func offer(_ offer: RetentionOffer, in context: RetentionMCPContext) -> JSONValue {
        let subscription = context.content.subscription(id: offer.subscriptionID)
        var json: [String: JSONValue] = [
            "subscriptionId": .string(offer.subscriptionID),
            "referenceName": .string(offer.referenceName),
            "offerId": .string(offer.offerID),
            "mode": .string(offer.mode.rawValue),
            "duration": .string(offer.duration.rawValue),
            "periods": .int(offer.periodCount),
            "paidMonths": .int(offer.paidMonths),
            "shown": .bool(offer.isShown),
            "queued": .bool(offer.isQueued),
            "terms": .string(offer.terms(basePrice: subscription?.basePrice, period: subscription?.period)),
        ]
        if !offer.isQueued { json["id"] = .string(offer.id) }
        if let price = offer.usPrice { json["usPrice"] = MCPPriceValue.json(price) }
        if let wait = offer.waitMonths { json["waitMonths"] = .int(wait) }
        return .object(json)
    }
}
