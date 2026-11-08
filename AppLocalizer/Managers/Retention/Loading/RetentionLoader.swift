//
//  RetentionLoader.swift
//  AppLocalizer
//

import Foundation

/// Reads an app's retention messages and its subscriptions' retention
/// offers. Each message shows the version that matters most: one still
/// being prepared (it takes edits), else one with Apple, else the live
/// one. Reads only; every write goes through Review & Push.
@MainActor
struct RetentionLoader {
    let transport: any PushTransport

    func content(for app: StoreApp, subscriptions: [RetentionSubscription]) async throws -> RetentionContent {
        let source = app.primaryLocale.flatMap(StoreLocaleCatalog.locale(code:)) ?? .englishUS
        var offers: [RetentionOffer] = []
        for subscription in subscriptions {
            offers += try await self.offers(of: subscription.id)
        }
        let shownBySubscription = Dictionary(grouping: offers.filter(\.isShown), by: \.subscriptionID)
        var messages: [RetentionMessage] = []
        for remote in try await remoteMessages(appID: app.id) {
            let kind: RetentionMessageKind = if remote.placementID != nil {
                .image
            } else if remote.subscriptionIDs.contains(where: { shownBySubscription[$0] != nil }) {
                .offer
            } else {
                .message
            }
            var image: RetentionImage?
            if let imageID = remote.imageID { image = try await self.image(id: imageID) }
            messages.append(RetentionMessage(remote: remote, image: image, kind: kind))
        }
        let codes = try await languageCodes(appID: app.id)
        return RetentionContent(
            subscriptions: subscriptions,
            messages: messages,
            offers: offers,
            languages: RetentionLanguages.languages(codes: codes, source: source),
            sourceLocale: source
        )
    }

    // MARK: - Messages

    func remoteMessages(appID: StoreApp.ID) async throws -> [RetentionRemoteMessage] {
        let path = "/v1/apps/\(appID)/retentionMessages?include=versions,subscriptions&limit=200"
            + "&limit%5Bversions%5D=50&limit%5Bsubscriptions%5D=50"
        let page = try await RetentionJSON.resources(at: path, via: transport)
        let versions = page.included.filter { $0["type"] as? String == "retentionMessageVersions" }
        var result: [RetentionRemoteMessage] = []
        for resource in page.data {
            guard let id = resource["id"] as? String else { continue }
            let versionIDs = RetentionJSON.relatedIDs("versions", of: resource)
            let own = versionIDs.compactMap { versionID in versions.first { $0["id"] as? String == versionID } }
            var message = RetentionRemoteMessage(
                messageID: id,
                referenceName: RetentionJSON.string("referenceName", of: resource) ?? "",
                subscriptionIDs: RetentionJSON.relatedIDs("subscriptions", of: resource)
            )
            let states = own.map { ($0["id"] as? String ?? "", RetentionVersionState(rawValue: RetentionJSON.string("state", of: $0) ?? "")) }
            message.hasLiveVersion = states.contains { $0.1?.isLive == true }
            if let chosen = Self.chosenVersion(states) {
                message.versionID = chosen.id
                message.versionState = chosen.state
                try await fillVersion(of: &message)
            }
            result.append(message)
        }
        return result
    }

    /// The version that takes edits, else the one with Apple, else the
    /// live one; the latest of a kind.
    static func chosenVersion(_ versions: [(String, RetentionVersionState?)]) -> (id: String, state: RetentionVersionState?)? {
        let ranked = versions.enumerated().max { lhs, rhs in
            let left = lhs.element.1?.priority ?? 0
            let right = rhs.element.1?.priority ?? 0
            return left == right ? lhs.offset < rhs.offset : left < right
        }
        return ranked.map { ($0.element.0, $0.element.1) }
    }

    /// The version's languages and image placement.
    private func fillVersion(of message: inout RetentionRemoteMessage) async throws {
        guard let versionID = message.versionID else { return }
        let path = "/v1/retentionMessageVersions/\(versionID)?include=localizations,placement&limit%5Blocalizations%5D=50"
        let page = try await RetentionJSON.resources(at: path, via: transport)
        for resource in page.included where resource["type"] as? String == "retentionMessageLocalizations" {
            guard let id = resource["id"] as? String, let locale = RetentionJSON.string("locale", of: resource) else { continue }
            message.localizations[locale] = RetentionRemoteLocalization(
                id: id,
                locale: locale,
                header: RetentionJSON.string("header", of: resource) ?? "",
                body: RetentionJSON.string("body", of: resource) ?? ""
            )
        }
        guard let version = page.data.first, let placementID = RetentionJSON.relatedID("placement", of: version) else { return }
        message.placementID = placementID
        let placement = try await RetentionJSON.resources(at: "/v1/retentionMessageVersions/\(versionID)/placement?include=image", via: transport)
        message.imageID = placement.data.first.flatMap { RetentionJSON.relatedID("image", of: $0) }
    }

    /// The library image a placement shows, for its name and size.
    private func image(id: String) async throws -> RetentionImage? {
        let page = try await RetentionJSON.resources(at: "/v1/appAssetLibraryImages/\(id)", via: transport)
        guard let resource = page.data.first else { return nil }
        let attributes = RetentionJSON.attributes(of: resource)
        let asset = attributes["imageAsset"] as? [String: Any]
        return RetentionImage(
            assetID: id,
            name: RetentionJSON.string("referenceName", of: resource) ?? RetentionJSON.string("fileName", of: resource) ?? id,
            fileName: RetentionJSON.string("fileName", of: resource),
            pixelWidth: (asset?["width"] as? NSNumber)?.intValue ?? RetentionLimits.imageWidth,
            pixelHeight: (asset?["height"] as? NSNumber)?.intValue ?? 0,
            thumbnailTemplate: asset?["templateUrl"] as? String
        )
    }

    // MARK: - Offers

    func offers(of subscriptionID: String) async throws -> [RetentionOffer] {
        let page = try await RetentionJSON.resources(at: "/v1/subscriptions/\(subscriptionID)/retentionOffers?limit=200", via: transport)
        let shown = try await RetentionJSON.resources(
            at: "/v1/subscriptions/\(subscriptionID)/relationships/retentionMessageOffers?limit=200", via: transport
        ).data.compactMap { $0["id"] as? String }
        var offers: [RetentionOffer] = []
        for resource in page.data {
            guard let id = resource["id"] as? String,
                  let mode = RetentionJSON.string("offerMode", of: resource).flatMap(RetentionOfferMode.init(rawValue:)),
                  let duration = RetentionJSON.string("duration", of: resource).flatMap(RetentionOfferDuration.init(rawValue:))
            else { continue }
            let offerID = RetentionJSON.string("offerId", of: resource) ?? id
            var price: Decimal?
            if mode.hasPrice { price = try await usPrice(of: id) }
            offers.append(RetentionOffer(
                id: id,
                subscriptionID: subscriptionID,
                referenceName: RetentionJSON.string("referenceName", of: resource) ?? offerID,
                offerID: offerID,
                mode: mode,
                duration: duration,
                periodCount: RetentionJSON.int("periodCount", of: resource) ?? 1,
                usPrice: price,
                paidMonths: RetentionJSON.int("customerEligibilityPaidSubscriptionDurationInMonths", of: resource) ?? 1,
                waitMonths: RetentionJSON.int("customerEligibilityWaitBetweenOffersInMonths", of: resource),
                isShown: shown.contains(id)
            ))
        }
        return offers
    }

    /// The offer's price in the United States.
    private func usPrice(of offerID: String) async throws -> Decimal? {
        let path = "/v1/retentionOffers/\(offerID)/prices?filter%5Bterritory%5D=USA&include=subscriptionPricePoint"
        let page = try await RetentionJSON.resources(at: path, via: transport)
        let point = page.included.first { $0["type"] as? String == "subscriptionPricePoints" }
        return point.flatMap { RetentionJSON.decimal(RetentionJSON.string("customerPrice", of: $0)) }
    }

    // MARK: - Languages

    /// The locales of the app's App Store information.
    func languageCodes(appID: StoreApp.ID) async throws -> [String] {
        let path = "/v1/apps/\(appID)/appInfos?include=appInfoLocalizations&fields%5BappInfoLocalizations%5D=locale"
            + "&limit%5BappInfoLocalizations%5D=50"
        let page = try await RetentionJSON.resources(at: path, via: transport)
        let codes = page.included.compactMap { RetentionJSON.string("locale", of: $0) }
        return Array(Set(codes)).sorted()
    }
}
