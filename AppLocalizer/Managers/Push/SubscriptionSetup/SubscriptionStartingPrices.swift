//
//  SubscriptionStartingPrices.swift
//  AppLocalizer
//

import Foundation

/// A subscription's first prices: a `POST /v1/subscriptionPrices` whose
/// price point is `{startingPrice:<territory>:<price>}`. Price points
/// belong to one subscription, so a new one's can only be read once it
/// exists; the push reads them then, sets the price in that territory and
/// Apple's equalized price everywhere else, like App Store Connect's
/// "Set Starting Price". A territory that has a price by then keeps it, so
/// a retry picks up where it stopped.
struct SubscriptionStartingPrices: Hashable, Sendable {
    var subscriptionID: String
    /// The base territory, `USA`.
    var territoryID: String
    var customerPrice: Decimal

    static let placeholderPrefix = "{startingPrice:"

    static func placeholder(territoryID: String, price: Decimal) -> String {
        "\(placeholderPrefix)\(territoryID):\(NSDecimalNumber(decimal: price).stringValue)}"
    }

    /// The queued request: `subscriptionID` may be `{createdID:subscriptions}`.
    static func request(subscriptionID: String, territoryID: String, price: Decimal) -> PushRequest {
        let body = SubscriptionPriceCreateRequest(
            subscriptionID: subscriptionID,
            territoryID: territoryID,
            pricePointID: placeholder(territoryID: territoryID, price: price),
            preserveCurrentPrice: false
        )
        return (try? PushRequest.json(.post, path, body)) ?? PushRequest(method: .post, path: path)
    }

    private static let path = "/v1/subscriptionPrices"

    init?(_ request: PushRequest) {
        guard request.method == .post, request.path == Self.path, let body = request.body,
              let document = try? JSONDecoder().decode(SubscriptionPriceCreateRequest.self, from: body)
        else { return nil }
        let point = document.data.relationships.subscriptionPricePoint.data.id
        guard point.hasPrefix(Self.placeholderPrefix), point.hasSuffix("}") else { return nil }
        let parts = point.dropFirst(Self.placeholderPrefix.count).dropLast().split(separator: ":").map(String.init)
        guard parts.count == 2, let price = Decimal(string: parts[1], locale: Locale(identifier: "en_US_POSIX")) else { return nil }
        subscriptionID = document.data.relationships.subscription.data.id
        territoryID = parts[0]
        customerPrice = price
    }

    // MARK: - Reads

    /// `GET` the subscription's price points in the base territory.
    var pricePointsPath: String {
        "/v1/subscriptions/\(subscriptionID)/pricePoints?filter%5Bterritory%5D=\(territoryID)"
            + "&fields%5BsubscriptionPricePoints%5D=customerPrice&limit=8000"
    }

    /// `GET` the points Apple equalizes with the base one, with their territory.
    func equalizationsPath(pricePointID: String) -> String {
        "/v1/subscriptionPricePoints/\(pricePointID)/equalizations?include=territory"
            + "&fields%5BsubscriptionPricePoints%5D=customerPrice,territory&fields%5Bterritories%5D=currency&limit=200"
    }

    /// `GET` the prices the subscription has, with their territory.
    var pricesPath: String {
        "/v1/subscriptions/\(subscriptionID)/prices?include=territory&fields%5BsubscriptionPrices%5D=territory"
            + "&fields%5Bterritories%5D=currency&limit=200"
    }

    /// The base territory's point at exactly `customerPrice`.
    func pricePointID(in resources: [[String: Any]]) -> String? {
        resources.first { Self.price(of: $0) == customerPrice }?["id"] as? String
    }

    /// The prices just below and above `customerPrice`, for the refusal.
    func nearest(in resources: [[String: Any]]) -> [Decimal] {
        let prices = resources.compactMap(Self.price(of:)).sorted()
        return [prices.last { $0 < customerPrice }, prices.first { $0 > customerPrice }].compactMap(\.self)
    }

    /// Each resource's territory: `relationships.territory.data.id`.
    static func territoryID(of resource: [String: Any]) -> String? {
        let relationships = resource["relationships"] as? [String: Any]
        let territory = relationships?["territory"] as? [String: Any]
        return (territory?["data"] as? [String: Any])?["id"] as? String
    }

    /// `POST` one territory's price, at once.
    func price(territoryID: String, pricePointID: String) -> PushRequest {
        let body = SubscriptionPriceCreateRequest(
            subscriptionID: subscriptionID,
            territoryID: territoryID,
            pricePointID: pricePointID,
            preserveCurrentPrice: false
        )
        return (try? PushRequest.json(.post, Self.path, body)) ?? PushRequest(method: .post, path: Self.path)
    }

    // MARK: - Sending

    /// Reads the points and sets every price that's missing. `progress`
    /// gets (set, total) after each one and `note` each response's rate
    /// limit. Throws `SubscriptionStartingPriceError` when Apple has no
    /// point at that price. On the main actor, like the push that reports
    /// the progress.
    @MainActor
    func send(
        via transport: any PushTransport,
        progress: (Int, Int) -> Void,
        note: (AppStoreConnectRateLimit?) -> Void
    ) async throws {
        let points = try await Self.resources(at: pricePointsPath, via: transport, note: note)
        guard let baseID = pricePointID(in: points) else {
            throw SubscriptionStartingPriceError.noPricePoint(price: customerPrice, territoryID: territoryID, nearest: nearest(in: points))
        }
        let equalized = try await Self.resources(at: equalizationsPath(pricePointID: baseID), via: transport, note: note)
        let priced = try await Set(Self.resources(at: pricesPath, via: transport, note: note).compactMap(Self.territoryID(of:)))
        var wanted = [(territoryID, baseID)]
        for point in equalized {
            guard let territory = Self.territoryID(of: point), let id = point["id"] as? String, territory != territoryID else { continue }
            wanted.append((territory, id))
        }
        let missing = wanted.filter { !priced.contains($0.0) }
        for (index, entry) in missing.enumerated() {
            let response = try await transport.send(price(territoryID: entry.0, pricePointID: entry.1))
            note(response.rateLimit)
            progress(index + 1, missing.count)
        }
    }

    /// Every page's `data`, following `links.next`.
    @MainActor
    private static func resources(
        at path: String,
        via transport: any PushTransport,
        note: (AppStoreConnectRateLimit?) -> Void
    ) async throws -> [[String: Any]] {
        var next: String? = path
        var result: [[String: Any]] = []
        while let page = next {
            let response = try await transport.fetch(page)
            note(response.rateLimit)
            let object = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any]
            result += object?["data"] as? [[String: Any]] ?? []
            next = (object?["links"] as? [String: Any])?["next"] as? String
        }
        return result
    }

    private static func price(of resource: [String: Any]) -> Decimal? {
        let attributes = resource["attributes"] as? [String: Any]
        return (attributes?["customerPrice"] as? String).flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) }
    }
}
