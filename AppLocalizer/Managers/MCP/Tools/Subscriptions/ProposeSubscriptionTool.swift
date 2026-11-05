//
//  ProposeSubscriptionTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_subscription`: an assistant's new subscription, checked like
/// Create Subscription in Pricing and queued for review as one change. The
/// push creates the group when it's new, the subscription, its texts,
/// availability everywhere and the starting price, equalized everywhere.
struct ProposeSubscriptionTool: MCPTool {
    /// The arguments, typed apart so the definition type-checks quickly.
    private static let properties: [String: JSONValue] = [
        "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
        "group": MCPToolDefinition.string("An existing group's id or reference name, or a new group's reference name."),
        "groupDisplayName": MCPToolDefinition.string("A new group's name on the App Store, in locale (≤30)."),
        "referenceName": MCPToolDefinition.string("The subscription's internal name in App Store Connect, e.g. Bruma Premium Monthly (≤64)."),
        "productId": MCPToolDefinition.string("The product ID the app's code buys, e.g. com.example.app.premium.monthly."),
        "duration": [
            "type": "string",
            "enum": .array(SubscriptionPeriod.allCases.map { .string($0.rawValue) }),
            "description": "How long one billing period lasts.",
        ],
        "displayName": MCPToolDefinition.string("What customers see on the purchase sheet (≤30)."),
        "description": MCPToolDefinition.string("What subscribers get (≤45)."),
        "price": [
            "type": ["number", "string"],
            "description": "The starting price in the United States in US dollars, e.g. 9.99.",
        ],
        "familySharing": ["type": "boolean", "description": "Whether Family Sharing is on. It can't be turned off later."],
        "reviewNote": MCPToolDefinition.string("Optional notes for App Review, e.g. how to reach the paywall."),
        "locale": MCPToolDefinition.string("The App Store Connect locale of displayName and description, e.g. en-US."),
        "evidence": [
            "type": "array",
            "items": ["type": "string"],
            "description": "Where the code sells it, e.g. Bruma/Store/Products.swift:12 — buys com.example.app.premium.monthly",
        ],
    ]

    let definition = MCPToolDefinition(
        name: "propose_subscription",
        title: "Propose Subscription",
        description: """
        Proposes a new auto-renewable subscription for an app, e.g. one its StoreKit code buys that App Store \
        Connect doesn't have yet (see get_subscriptions). group is an existing group's id or reference name; any \
        other name makes a new group, which needs groupDisplayName (its App Store name). The product ID must be \
        exactly the one the app's code uses; it can't be changed or reused once created. duration is ONE_WEEK, \
        ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS or ONE_YEAR. displayName (≤30) and description (≤45) are \
        written in locale (the app's primary language when left out); price is the starting price in the United \
        States in US dollars, and every other territory gets Apple's equalized price. Anything App Store Connect \
        would refuse is refused with the reasons (status "refused"). An accepted proposal is queued for the \
        person to review (status "queued"); proposing the same productId again replaces it. Nothing reaches App \
        Store Connect until they push.
        """,
        inputSchema: MCPToolDefinition.schema(
            Self.properties,
            required: ["appId", "group", "referenceName", "productId", "duration", "displayName", "description", "price"]
        ),
        proposalKind: .prices
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let catalog = try await MCPPriceCatalog.load(app: arguments.string("appId"), in: context.workspace)
        let app = catalog.app
        let subscription = try Self.subscription(from: arguments, app: app, catalog: catalog.catalog)
        let builder = NewSubscriptionChangeBuilder(app: app)
        let productID = NewSubscription.trimmed(subscription.productID)
        let id = NewSubscriptionChangeBuilder.changeID(appID: app.id, productID: productID)
        let target = "\(app.name) · \(NewSubscription.trimmed(subscription.referenceName))"
        let queue = context.workspace.changes

        var reasons: [String] = []
        if let existing = queue.change(id: id), existing.source != .assistant(client: context.clientName) {
            reasons.append(String(localized: "\(existing.source.title) already has a new subscription with this product ID in Review & Push."))
        }
        let taken = NewSubscriptionChangeBuilder.takenProductIDs(appID: app.id, catalog: catalog.catalog, queue: queue, except: id)
        let groupNames = catalog.catalog.groups.filter { !$0.isInAppPurchases }.map(\.name)
        reasons += subscription.problems(takenProductIDs: taken, groupNames: groupNames).map(\.message)
        guard reasons.isEmpty else {
            let result: JSONValue = ["status": "refused", "productId": .string(productID), "reasons": .array(reasons.map { .string($0) })]
            return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: target, outcome: .refused, reason: reasons.joined(separator: " "))])
        }
        let evidence = try arguments.optionalStrings("evidence") ?? []
        queue.upsert(builder.change(for: subscription, source: .assistant(client: context.clientName), evidence: evidence))
        let result: JSONValue = [
            "status": "queued",
            "changeId": .string(id),
            "productId": .string(productID),
            "group": .string(subscription.group.isNew ? "\(subscription.group.referenceName) (new)" : subscription.group.referenceName),
            "note": """
            When the person pushes, App Store Connect gets the subscription with its texts, availability everywhere and \
            the starting price. Its review screenshot is added in App Store Connect; other languages through \
            propose_in_app_texts once it exists.
            """,
        ]
        return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: target, outcome: .proposed)])
    }

    /// The arguments as a new subscription; throws for one that isn't
    /// usable at all (an unknown duration or locale, a price that isn't a
    /// number).
    private static func subscription(from arguments: MCPToolArguments, app: StoreApp, catalog: PricingCatalog) throws -> NewSubscription {
        let durationText = try arguments.string("duration")
        guard let period = SubscriptionPeriod(rawValue: durationText.uppercased()) else {
            let names = SubscriptionPeriod.allCases.map(\.rawValue).joined(separator: ", ")
            throw MCPToolError.invalidArgument(name: "duration", expected: String(localized: "one of \(names)"))
        }
        let localeCode = try arguments.optionalString("locale") ?? app.primaryLocale ?? StoreLocale.englishUS.code
        guard let locale = StoreLocaleCatalog.locale(code: localeCode) else {
            throw MCPToolError.invalidArgument(name: "locale", expected: String(localized: "an App Store Connect locale code, e.g. en-US"))
        }
        guard let value = arguments.values["price"], let price = MCPPriceValue.decimal(from: value) else {
            throw MCPToolError.invalidArgument(name: "price", expected: String(localized: "a positive price in US dollars, e.g. 9.99"))
        }
        let groupName = try arguments.string("group")
        let wanted = NewSubscription.trimmed(groupName)
        let existing = catalog.groups.first { group in
            !group.isInAppPurchases && (group.id == wanted || group.name.compare(wanted, options: .caseInsensitive) == .orderedSame)
        }
        let group: NewSubscriptionGroup = if let existing {
            .existing(id: existing.id, referenceName: existing.name)
        } else {
            try .new(referenceName: wanted, displayName: arguments.optionalString("groupDisplayName") ?? "")
        }
        return try NewSubscription(
            group: group,
            referenceName: arguments.string("referenceName"),
            productID: arguments.string("productId"),
            period: period,
            isFamilySharable: arguments.optionalBool("familySharing") ?? false,
            locale: locale,
            displayName: arguments.string("displayName"),
            description: arguments.string("description"),
            price: price,
            reviewNote: arguments.optionalString("reviewNote") ?? ""
        )
    }
}
