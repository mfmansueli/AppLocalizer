//
//  RetentionQueuedChanges.swift
//  AppLocalizer
//

import Foundation

/// Reads queued retention changes back into messages and offers, so the
/// page shows what Review & Push will send, also after a relaunch: the
/// names, words and who wrote them from the change's rows, and the
/// subscriptions, image and offers from its requests.
enum RetentionQueuedChanges {
    /// The message a queued change makes, on top of App Store Connect's
    /// copy (`remote`) when it's an existing one.
    static func message(from change: PendingChange, remote: RetentionMessage?) -> RetentionMessage? {
        guard let id = RetentionChangeBuilder.messageID(of: change), let fields = change.creation?.fields else { return nil }
        var message = remote ?? RetentionMessage(id: id, referenceName: "")
        func value(_ fieldID: String) -> String? {
            fields.first { $0.id == fieldID }?.newValue
        }
        if let name = value("name"), !name.isEmpty { message.referenceName = name }
        if let shows = value("shows"), let kind = RetentionMessageKind.allCases.first(where: { $0.summary == shows }) {
            message.kind = kind
        }
        var subscriptions = message.subscriptionIDs
        for request in change.requests where request.method == .patch && request.path.hasSuffix("/relationships/retentionMessage") {
            let id = request.path.replacingOccurrences(of: "/v1/subscriptions/", with: "").replacingOccurrences(of: "/relationships/retentionMessage", with: "")
            if !subscriptions.contains(id) { subscriptions.append(id) }
        }
        message.subscriptionIDs = subscriptions
        if message.kind == .image, let image = image(from: change, name: value("image")) { message.image = image }
        var texts = message.texts
        for field in fields where field.id.hasPrefix("header.") {
            let code = String(field.id.dropFirst("header.".count))
            let body = value("body.\(code)") ?? ""
            texts[code] = RetentionText(header: field.newValue, body: body, origin: origin(of: field.source))
        }
        message.texts = texts.filter { !$0.value.isEmpty || remote?.texts[$0.key] != nil }
        return message
    }

    /// The image a queued placement shows: from the Asset Library, or a
    /// file on this Mac still to upload.
    static func image(from change: PendingChange, name: String?) -> RetentionImage? {
        guard let placement = change.requests.first(where: { $0.path == RetentionRequests.placementsPath }),
              let data = RetentionRequests.object(of: placement)?["data"] as? [String: Any],
              let imageID = RetentionJSON.relatedID("image", of: data)
        else { return nil }
        let size = RetentionPushSteps.token(RetentionPushSteps.placementGroupPrefix, in: placement).map { RetentionPlacementGroup(size: $0.value) }
        let upload = RetentionImageUpload(in: placement)
        let title = name?.components(separatedBy: " · ").first ?? upload?.fileName ?? imageID
        return RetentionImage(
            assetID: upload == nil ? imageID : nil,
            name: title,
            fileName: upload?.fileName,
            pixelWidth: size?.width ?? RetentionLimits.imageWidth,
            pixelHeight: size?.height ?? 0,
            localPath: upload?.path,
            isPNG: upload.map { $0.path.lowercased().hasSuffix(".png") }
        )
    }

    static func origin(of source: ChangeSource) -> RetentionTextOrigin {
        switch source {
        case .machineTranslation, .aiProvider: .translated
        case let .assistant(client): .assistant(client: client)
        default: .written
        }
    }

    /// The offer a queued offer change creates.
    static func offer(from change: PendingChange) -> RetentionOffer? {
        guard change.id.hasPrefix(RetentionChangeBuilder.offerPrefix),
              let create = change.requests.first(where: { $0.path == RetentionRequests.offersPath }),
              let data = RetentionRequests.object(of: create)?["data"] as? [String: Any],
              let subscriptionID = RetentionJSON.relatedID("subscription", of: data),
              let offerID = RetentionJSON.string("offerId", of: data),
              let mode = RetentionJSON.string("offerMode", of: data).flatMap(RetentionOfferMode.init(rawValue:)),
              let duration = RetentionJSON.string("duration", of: data).flatMap(RetentionOfferDuration.init(rawValue:))
        else { return nil }
        return RetentionOffer(
            id: "\(RetentionOffer.newPrefix)\(offerID)",
            subscriptionID: subscriptionID,
            referenceName: RetentionJSON.string("referenceName", of: data) ?? offerID,
            offerID: offerID,
            mode: mode,
            duration: duration,
            periodCount: RetentionJSON.int("periodCount", of: data) ?? 1,
            usPrice: RetentionOfferCreate(create)?.price?.amount,
            paidMonths: RetentionJSON.int("customerEligibilityPaidSubscriptionDurationInMonths", of: data) ?? 1,
            waitMonths: RetentionJSON.int("customerEligibilityWaitBetweenOffersInMonths", of: data),
            isShown: true,
            isQueued: true
        )
    }
}
