//
//  NewSubscriptionChangeBuilder.swift
//  AppLocalizer
//

import Foundation

/// Turns a new subscription into one Review & Push change, shown as
/// "Create Bruma Premium Monthly" with its fields. Its requests, in order:
///
/// 1. `POST /v1/subscriptions` into the group: an existing one's ID, or
///    `{subscriptionGroup:…}`, which the push finds or creates.
/// 2. A new group's display name (App Store Connect needs one to submit
///    the group), into its texts' version (`InAppDraftWrite`).
/// 3. The subscription's display name and description, the same way, into
///    `{createdID:subscriptions}`.
/// 4. Availability in every country or region, and in new ones.
/// 5. The starting price in the United States, equalized everywhere else
///    (`SubscriptionStartingPrices`).
///
/// A failure resumes after the steps that went through. A subscription
/// can't be deleted through the API once it's created, so the change has
/// nothing to restore. Its review screenshot is added in App Store Connect.
struct NewSubscriptionChangeBuilder {
    let app: StoreApp

    static let idPrefix = "subscriptionSetup."

    /// `subscriptionSetup.<appID>.<productID>`: proposing the same product
    /// ID again replaces the change.
    static func changeID(appID: StoreApp.ID, productID: String) -> PendingChange.ID {
        "\(idPrefix)\(appID).\(productID)"
    }

    /// `subscriptionSetup.<appID>.<productID>.startingPrice`.
    static func startingPriceChangeID(appID: StoreApp.ID, productID: String) -> PendingChange.ID {
        changeID(appID: appID, productID: productID) + ".startingPrice"
    }

    static func owns(_ change: PendingChange) -> Bool {
        change.id.hasPrefix(idPrefix)
    }

    /// The app's new subscriptions waiting in Review & Push.
    @MainActor
    static func queued(in queue: ChangeQueue, appID: StoreApp.ID) -> [PendingChange] {
        queue.changes(for: appID, section: .subscriptionPricing).filter { owns($0) && $0.creation != nil }
    }

    /// A queued new subscription's product ID.
    static func productID(of change: PendingChange) -> String? {
        change.creation?.fields.first { $0.id == "productId" }?.newValue
    }

    /// The product IDs a new subscription can't take: the app's products'
    /// and the other new subscriptions' in Review & Push.
    @MainActor
    static func takenProductIDs(appID: StoreApp.ID, catalog: PricingCatalog?, queue: ChangeQueue, except changeID: PendingChange.ID) -> Set<String> {
        let queued = queued(in: queue, appID: appID).filter { $0.id != changeID }.compactMap(productID(of:))
        return Set((catalog?.products.map(\.productID) ?? []) + queued)
    }

    var group: String { String(localized: "Subscription Pricing · New subscriptions") }

    func change(
        for subscription: NewSubscription,
        problems: [NewSubscriptionProblem] = [],
        source: ChangeSource = .you,
        evidence: [String] = [],
        at date: Date = .now
    ) -> PendingChange {
        let id = Self.changeID(appID: app.id, productID: NewSubscription.trimmed(subscription.productID))
        var change = PendingChange(
            id: id,
            appID: app.id,
            section: .subscriptionPricing,
            group: group,
            title: NewSubscription.trimmed(subscription.referenceName),
            oldValue: "",
            newValue: summary(of: subscription),
            source: source,
            blockedReason: problems.first?.message,
            requests: requests(for: subscription),
            createdAt: date
        )
        change.creation = PendingCreation(
            id: id,
            title: String(localized: "Create \(change.title)"),
            detail: detail(of: subscription),
            source: source,
            fields: fields(of: subscription, source: source, evidence: evidence)
        )
        return change
    }

    /// A subscription App Store Connect has without a price: its starting
    /// price in the United States, equalized everywhere else.
    func startingPriceChange(for product: PricingProduct, price: Decimal, source: ChangeSource = .you, at date: Date = .now) -> PendingChange {
        let formatted = CurrencyFormat.forCurrency("USD").format(price)
        return PendingChange(
            id: Self.startingPriceChangeID(appID: app.id, productID: product.productID),
            appID: app.id,
            section: .subscriptionPricing,
            group: String(localized: "Subscription Pricing · \(product.name)"),
            title: String(localized: "Starting price"),
            flagRegion: "US",
            oldValue: String(localized: "No price"),
            newValue: String(localized: "\(formatted) · equalized everywhere else"),
            source: source,
            blockedReason: NewSubscription.isValidPrice(price) ? nil : NewSubscriptionProblem.invalidPrice.message,
            requests: [SubscriptionStartingPrices.request(subscriptionID: product.id, territoryID: NewSubscription.baseTerritoryID, price: price)],
            createdAt: date
        )
    }

    // MARK: - Requests

    func requests(for subscription: NewSubscription) -> [PushRequest] {
        let groupID = switch subscription.group {
        case let .existing(id, _): id
        case let .new(referenceName, _):
            SubscriptionGroupPlaceholder.placeholder(appID: app.id, referenceName: NewSubscription.trimmed(referenceName))
        }
        let subscriptionID = PushRequest.createdIDPlaceholder(type: "subscriptions")
        var requests = [create(subscription, groupID: groupID)]
        if case let .new(_, displayName) = subscription.group {
            requests.append(texts(
                type: "subscriptionGroupLocalizations",
                attributes: ["locale": subscription.locale.code, "name": NewSubscription.trimmed(displayName)],
                ownerType: "subscriptionGroups",
                ownerID: groupID,
                versionType: "subscriptionGroupVersions"
            ))
        }
        var texts: [String: String?] = ["locale": subscription.locale.code, "name": NewSubscription.trimmed(subscription.displayName)]
        let description = NewSubscription.trimmed(subscription.description)
        if !description.isEmpty { texts["description"] = description }
        requests.append(self.texts(
            type: "subscriptionLocalizations",
            attributes: texts,
            ownerType: "subscriptions",
            ownerID: subscriptionID,
            versionType: "subscriptionVersions"
        ))
        requests.append(availability(subscriptionID: subscriptionID))
        if let price = subscription.price {
            requests.append(SubscriptionStartingPrices.request(subscriptionID: subscriptionID, territoryID: NewSubscription.baseTerritoryID, price: price))
        }
        return requests
    }

    private func create(_ subscription: NewSubscription, groupID: String) -> PushRequest {
        var attributes: [String: Any] = [
            "name": NewSubscription.trimmed(subscription.referenceName),
            "productId": NewSubscription.trimmed(subscription.productID),
            "subscriptionPeriod": subscription.period.rawValue,
            "familySharable": subscription.isFamilySharable,
        ]
        let note = NewSubscription.trimmed(subscription.reviewNote)
        if !note.isEmpty { attributes["reviewNote"] = note }
        return Self.post("/v1/subscriptions", [
            "data": [
                "type": "subscriptions",
                "attributes": attributes,
                "relationships": ["group": ["data": ["type": "subscriptionGroups", "id": groupID]]],
            ],
        ])
    }

    /// A localization `POST` into `{inAppDraft:<owner>}`.
    private func texts(type: String, attributes: [String: String?], ownerType: String, ownerID: String, versionType: String) -> PushRequest {
        let document = StorePageWriteDocument.create(
            type: type,
            attributes: attributes,
            parent: "version",
            parentType: versionType,
            parentID: PushRequest.inAppDraftPlaceholder(ownerType: ownerType, ownerID: ownerID)
        )
        return PushRequest(method: .post, path: "/v2/\(type)", body: document.encoded())
    }

    private func availability(subscriptionID: String) -> PushRequest {
        Self.post("/v1/subscriptionAvailabilities", [
            "data": [
                "type": "subscriptionAvailabilities",
                "attributes": ["availableInNewTerritories": true],
                "relationships": [
                    "subscription": ["data": ["type": "subscriptions", "id": subscriptionID]],
                    "availableTerritories": ["data": TerritoryCatalog.standard.territories.map { ["type": "territories", "id": $0.id] }],
                ],
            ],
        ])
    }

    private static func post(_ path: String, _ body: [String: Any]) -> PushRequest {
        let data = (try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys, .withoutEscapingSlashes])) ?? Data()
        return PushRequest(method: .post, path: path, body: data)
    }

    // MARK: - Review & Push

    /// "1 month · $9.99".
    private func summary(of subscription: NewSubscription) -> String {
        [subscription.period.title, subscription.formattedPrice].compactMap(\.self).joined(separator: " · ")
    }

    private func detail(of subscription: NewSubscription) -> String {
        let group = subscription.group.isNew
            ? String(localized: "a new group, \(subscription.group.referenceName)")
            : subscription.group.referenceName
        return String(localized: """
        A \(subscription.period.title) subscription for \(app.name) in \(group), available in every country or region. \
        Add its review screenshot in App Store Connect before you submit it.
        """)
    }

    private func fields(of subscription: NewSubscription, source: ChangeSource, evidence: [String]) -> [PendingChangePart] {
        let language = subscription.locale.name
        var fields: [(String, String, String)] = [
            ("productId", NewSubscriptionField.productID.title, NewSubscription.trimmed(subscription.productID)),
            ("group", String(localized: "Group"), subscription.group.isNew
                ? String(localized: "\(subscription.group.referenceName) (new)")
                : subscription.group.referenceName),
        ]
        if case let .new(_, displayName) = subscription.group {
            fields.append(("groupName", String(localized: "Group display name · \(language)"), NewSubscription.trimmed(displayName)))
        }
        fields += [
            ("period", String(localized: "Duration"), subscription.period.title),
            ("name", String(localized: "Display name · \(language)"), NewSubscription.trimmed(subscription.displayName)),
            ("description", String(localized: "Description · \(language)"), NewSubscription.trimmed(subscription.description)),
            ("price", NewSubscriptionField.price.title, subscription.formattedPrice.map {
                String(localized: "\($0) in the United States · equalized everywhere else")
            } ?? ""),
            ("familySharing", String(localized: "Family Sharing"), subscription.isFamilySharable ? String(localized: "On") : String(localized: "Off")),
        ]
        let note = NewSubscription.trimmed(subscription.reviewNote)
        if !note.isEmpty { fields.append(("reviewNote", NewSubscriptionField.reviewNote.title, note)) }
        if !evidence.isEmpty { fields.append(("evidence", String(localized: "Found in"), evidence.joined(separator: "\n"))) }
        return fields.map { PendingChangePart(id: $0.0, title: $0.1, oldValue: "", newValue: $0.2, source: source) }
    }
}
