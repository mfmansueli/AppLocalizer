//
//  RetentionRequests.swift
//  AppLocalizer
//

import Foundation

/// The App Store Connect writes (API 4.6) a retention message or offer
/// becomes, as Review & Push sends them. IDs that only exist once an
/// earlier request created them are `{createdID:<type>}`; the placement
/// group, an image still on this Mac and an offer's prices are filled in
/// by the push (`RetentionPushSteps`).
enum RetentionRequests {
    static let messagesPath = "/v1/retentionMessages"
    static let versionsPath = "/v1/retentionMessageVersions"
    static let localizationsPath = "/v1/retentionMessageLocalizations"
    static let offersPath = "/v1/retentionOffers"
    static let placementsPath = "/v1/appAssetLibraryPlacements"
    static let reviewSubmissionsPath = "/v1/reviewSubmissions"
    static let reviewItemsPath = "/v1/reviewSubmissionItems"
    static let placementType = "RETENTION_MESSAGE_ASSET"

    /// `POST /v1/retentionMessages`: the message, with its reference name.
    static func createMessage(appID: String, referenceName: String) -> PushRequest {
        request(.post, messagesPath, [
            "data": [
                "type": "retentionMessages",
                "attributes": ["referenceName": referenceName],
                "relationships": ["app": ["data": ["type": "apps", "id": appID]]],
            ],
        ])
    }

    /// `PATCH /v1/subscriptions/{id}/relationships/retentionMessage`: the
    /// subscription shows the message, instead of any other.
    static func assign(subscriptionID: String, messageID: String) -> PushRequest {
        request(.patch, assignPath(subscriptionID: subscriptionID), ["data": ["type": "retentionMessages", "id": messageID]])
    }

    static func assignPath(subscriptionID: String) -> String {
        "/v1/subscriptions/\(subscriptionID)/relationships/retentionMessage"
    }

    /// `POST /v1/retentionMessageVersions`: new content for the message,
    /// showing the image placement when there is one. A version can't be
    /// changed once it's made, so the placement comes first.
    static func createVersion(messageID: String, placementID: String?) -> PushRequest {
        var relationships: [String: Any] = ["retentionMessage": ["data": ["type": "retentionMessages", "id": messageID]]]
        if let placementID {
            relationships["placement"] = ["data": ["type": "appAssetLibraryPlacements", "id": placementID]]
        }
        return request(.post, versionsPath, ["data": ["type": "retentionMessageVersions", "relationships": relationships]])
    }

    /// `POST /v1/retentionMessageLocalizations`: one language's header and
    /// message in a version.
    static func createLocalization(versionID: String, locale: String, text: RetentionText) -> PushRequest {
        request(.post, localizationsPath, [
            "data": [
                "type": "retentionMessageLocalizations",
                "attributes": [
                    "locale": locale,
                    "header": RetentionText.trimmed(text.header),
                    "body": RetentionText.trimmed(text.body),
                ],
                "relationships": ["retentionMessageVersion": ["data": ["type": "retentionMessageVersions", "id": versionID]]],
            ],
        ])
    }

    /// `PATCH /v1/retentionMessageLocalizations/{id}`: new words for a
    /// language the version has.
    static func updateLocalization(id: String, text: RetentionText) -> PushRequest {
        request(.patch, "\(localizationsPath)/\(id)", [
            "data": [
                "type": "retentionMessageLocalizations",
                "id": id,
                "attributes": ["header": RetentionText.trimmed(text.header), "body": RetentionText.trimmed(text.body)],
            ],
        ])
    }

    /// `DELETE /v1/retentionMessageLocalizations/{id}`.
    static func deleteLocalization(id: String) -> PushRequest {
        PushRequest(method: .delete, path: "\(localizationsPath)/\(id)")
    }

    /// `POST /v1/appAssetLibraryPlacements`: the image on the message, in
    /// the placement group Apple's reference data names for its size.
    static func placeImage(imageID: String, pixelWidth: Int, pixelHeight: Int) -> PushRequest {
        request(.post, placementsPath, [
            "data": [
                "type": "appAssetLibraryPlacements",
                "attributes": [
                    "placementType": placementType,
                    "placementGroup": RetentionPushSteps.placementGroupPlaceholder(width: pixelWidth, height: pixelHeight),
                ],
                "relationships": ["image": ["data": ["type": "appAssetLibraryImages", "id": imageID]]],
            ],
        ])
    }

    /// `POST /v1/subscriptions/{id}/relationships/retentionMessageOffers`:
    /// Apple may show these offers with the subscription's message.
    static func showOffers(subscriptionID: String, offerIDs: [String]) -> PushRequest {
        request(.post, offersLinkPath(subscriptionID: subscriptionID), ["data": offerIDs.map { ["type": "retentionOffers", "id": $0] }])
    }

    /// The same body with `DELETE`: Apple stops showing them.
    static func hideOffers(subscriptionID: String, offerIDs: [String]) -> PushRequest {
        request(.delete, offersLinkPath(subscriptionID: subscriptionID), ["data": offerIDs.map { ["type": "retentionOffers", "id": $0] }])
    }

    static func offersLinkPath(subscriptionID: String) -> String {
        "/v1/subscriptions/\(subscriptionID)/relationships/retentionMessageOffers"
    }

    /// `POST /v1/retentionOffers` with its prices: the price in the United
    /// States and Apple's equalized one everywhere else, filled in by the
    /// push from `{retentionOfferPrices:USA:<price>}`. A free offer sends
    /// no prices (untested against Apple).
    static func createOffer(_ offer: RetentionOffer) -> PushRequest {
        var attributes: [String: Any] = [
            "referenceName": offer.referenceName,
            "offerId": offer.offerID,
            "duration": offer.duration.rawValue,
            "offerMode": offer.mode.rawValue,
            "periodCount": offer.periodCount,
            "customerEligibilityPaidSubscriptionDurationInMonths": offer.paidMonths,
        ]
        if let wait = offer.waitMonths { attributes["customerEligibilityWaitBetweenOffersInMonths"] = wait }
        var prices: [[String: Any]] = []
        if offer.mode.hasPrice, let price = offer.usPrice {
            prices = [["type": "retentionOfferPrices", "id": RetentionPushSteps.offerPricesPlaceholder(territoryID: "USA", price: price)]]
        }
        return request(.post, offersPath, [
            "data": [
                "type": "retentionOffers",
                "attributes": attributes,
                "relationships": [
                    "subscription": ["data": ["type": "subscriptions", "id": offer.subscriptionID]],
                    "prices": ["data": prices],
                ],
            ],
            "included": [] as [Any],
        ])
    }

    /// `POST /v1/reviewSubmissions`: a submission for the app, without an
    /// app version.
    static func createReviewSubmission(appID: String) -> PushRequest {
        request(.post, reviewSubmissionsPath, [
            "data": ["type": "reviewSubmissions", "relationships": ["app": ["data": ["type": "apps", "id": appID]]]],
        ])
    }

    /// `POST /v1/reviewSubmissionItems`: the message version goes to App
    /// Review in that submission.
    static func addReviewItem(submissionID: String, versionID: String) -> PushRequest {
        request(.post, reviewItemsPath, [
            "data": [
                "type": "reviewSubmissionItems",
                "relationships": [
                    "reviewSubmission": ["data": ["type": "reviewSubmissions", "id": submissionID]],
                    "retentionMessageVersion": ["data": ["type": "retentionMessageVersions", "id": versionID]],
                ],
            ],
        ])
    }

    /// `PATCH /v1/reviewSubmissions/{id}` with `submitted: true`.
    static func submit(submissionID: String) -> PushRequest {
        request(.patch, "\(reviewSubmissionsPath)/\(submissionID)", [
            "data": ["type": "reviewSubmissions", "id": submissionID, "attributes": ["submitted": true]],
        ])
    }

    static func request(_ method: PushRequest.Method, _ path: String, _ body: Any) -> PushRequest {
        let data = (try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys, .withoutEscapingSlashes])) ?? Data()
        return PushRequest(method: method, path: path, body: data)
    }

    /// A request's body as JSON, for reading queued changes back.
    static func object(of request: PushRequest) -> [String: Any]? {
        request.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
    }
}
