//
//  RetentionPushSteps.swift
//  AppLocalizer
//

import Foundation

/// What a retention push fills in or sends itself, beyond the queued
/// requests: the image's placement group, from Apple's reference data;
/// an image Claude Design made on this Mac, uploaded to the Asset Library
/// first; an offer's prices, the U.S. price point and Apple's equalized
/// ones; a message a push before already created; and a refused review
/// submission, explained. `PushController` calls `resolving` before each
/// request and `sendSetupStep` instead of sending it.
enum RetentionPushSteps {
    static let placementGroupPrefix = "{retentionPlacementGroup:"
    static let uploadPrefix = "{retentionImageUpload:"
    static let offerPricesPrefix = "{retentionOfferPrices:"

    /// `{retentionPlacementGroup:3840x1000}`.
    static func placementGroupPlaceholder(width: Int, height: Int) -> String {
        "\(placementGroupPrefix)\(width)x\(height)}"
    }

    /// `{retentionImageUpload:<appID>:<percent-encoded path>}`.
    static func uploadPlaceholder(path: String, appID: StoreApp.ID) -> String {
        "\(uploadPrefix)\(appID):\(path.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? path)}"
    }

    /// `{retentionOfferPrices:USA:2.49}`.
    static func offerPricesPlaceholder(territoryID: String, price: Decimal) -> String {
        "\(offerPricesPrefix)\(territoryID):\(NSDecimalNumber(decimal: price).stringValue)}"
    }

    /// The first `prefix…}` in the request's body: the whole token and
    /// what's between the prefix and the brace.
    static func token(_ prefix: String, in request: PushRequest) -> (token: String, value: String)? {
        guard let text = request.body.flatMap({ String(data: $0, encoding: .utf8) }),
              let start = text.range(of: prefix),
              let end = text[start.upperBound...].firstIndex(of: "}")
        else { return nil }
        return (String(text[start.lowerBound...end]), String(text[start.upperBound..<end]))
    }

    /// The key an uploaded image's asset ID is kept under in the item's
    /// created IDs, so a retry doesn't upload it again.
    static func uploadKey(_ token: String) -> String {
        "retentionImage:\(token)"
    }

    // MARK: - Placeholders

    /// The request with its placement group and image upload filled in,
    /// and the IDs the item keeps (an uploaded image's).
    @MainActor
    static func resolving(
        _ request: PushRequest,
        known: [String: String],
        via transport: any PushTransport,
        note: (AppStoreConnectRateLimit?) -> Void
    ) async throws -> (request: PushRequest, created: [String: String]) {
        var request = request
        var created: [String: String] = [:]
        var category: String?
        // The group first: a size Apple doesn't take stops before uploading.
        if let group = token(placementGroupPrefix, in: request) {
            let resolved = try await RetentionPlacementGroup(size: group.value).resolve(via: transport, note: note)
            request = request.replacing(group.token, with: resolved.groupID)
            category = resolved.category
        }
        if let upload = RetentionImageUpload(in: request) {
            let key = uploadKey(upload.token)
            let id: String
            if let known = known[key] {
                id = known
            } else {
                id = try await upload.send(via: transport, category: category ?? RetentionImageUpload.category)
                created[key] = id
            }
            request = request.replacing(upload.token, with: id)
        }
        return (request, created)
    }

    // MARK: - Setup steps

    /// Sends `request` when it's a retention step that's more than one
    /// write, telling `created` the resource it made or found (type, ID).
    /// False for any other request.
    @MainActor
    static func sendSetupStep(
        _ request: PushRequest,
        via transport: any PushTransport,
        note: (AppStoreConnectRateLimit?) -> Void,
        created: (_ type: String, _ id: String) -> Void
    ) async throws -> Bool {
        if let create = RetentionMessageCreate(request) {
            try await created("retentionMessages", create.send(via: transport, note: note))
            return true
        }
        if let create = RetentionOfferCreate(request) {
            try await created("retentionOffers", create.send(via: transport, note: note))
            return true
        }
        guard request.method == .post, request.path == RetentionRequests.reviewSubmissionsPath else { return false }
        do {
            let response = try await transport.send(request)
            note(response.rateLimit)
            if let resource = RetentionJSON.resource(in: response.data) { created(resource.type, resource.id) }
            return true
        } catch let refusal as AppStoreConnectError {
            guard case let .rejected(_, _, detail) = refusal else { throw refusal }
            throw RetentionPushError.submissionRefused(detail: detail)
        }
    }
}
