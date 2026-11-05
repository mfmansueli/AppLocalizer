//
//  MCPInAppTextsDraft.swift
//  AppLocalizer
//

import Foundation

/// One app's In-App Texts as an assistant sees them: the subscription
/// group name and each subscription's and in-app purchase's name and
/// description per locale, App Store Connect's values with everything
/// already queued laid on top, exactly as Store Page → In-App Texts shows
/// them. Proposals change the draft; `commit(to:)` queues them the way the
/// view does, so an open In-App Texts view picks them up from the queue.
@MainActor
struct MCPInAppTextsDraft {
    let app: StoreApp
    let content: InAppTextsContent
    let builder: InAppTextChangeBuilder
    private(set) var matrix: InAppTextMatrix
    /// Cells a proposal changed since loading.
    private var touched: [Cell] = []

    /// One cell of the matrix.
    struct Cell: Hashable {
        let column: InAppTextColumn
        let locale: StoreLocale

        /// `de-DE.group.name`, for matching results to change ids.
        var key: String { "\(locale.code).\(column.id)" }
    }

    /// How one proposal went.
    enum Outcome: Equatable {
        /// Laid on the draft; `commit(to:)` says which change holds it.
        case queued
        /// Already the cell's text; nothing new was queued (or a proposal
        /// back to App Store Connect's text was withdrawn).
        case unchanged
        case refused(reason: String, count: Int? = nil, limit: ListingTextLimit? = nil)

        var isQueued: Bool { if case .queued = self { true } else { false } }
        var isRefused: Bool { if case .refused = self { true } else { false } }
    }

    static func load(app identifier: String, in workspace: MCPWorkspace) async throws -> MCPInAppTextsDraft {
        let app = try await workspace.app(matching: identifier)
        let services = workspace.services.storePage
        let content: InAppTextsContent
        do {
            content = try await services.inAppTexts(for: app)
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t read \(app.name)’s in-app texts: \(error.localizedDescription)"))
        }
        // The view lists the store page's locales; without a readable store
        // page, the in-app texts' own.
        let page = try? await services.content(for: app, versionID: nil)
        let primary = page?.primaryLocale ?? app.primaryLocale.flatMap { StoreLocaleCatalog.resolve($0).locale } ?? .englishUS
        var matrix = content.matrix(primaryLocale: primary, locales: page?.locales ?? content.locales)
        let builder = InAppTextChangeBuilder(appID: app.id, content: content)
        builder.apply(workspace.changes.changes(for: app.id, section: .storePage), to: &matrix)
        return MCPInAppTextsDraft(app: app, content: content, builder: builder, matrix: matrix)
    }

    // MARK: - Reading

    /// "Alba: Daily Motivation · In-App Texts".
    var target: String { String(localized: "\(app.name) · In-App Texts") }

    /// "Alba: Daily Motivation · de-DE · Group name".
    func target(locale code: String, column: InAppTextColumn?) -> String {
        [app.name, code, column?.title].compactMap(\.self).joined(separator: " · ")
    }

    func column(id: String) -> InAppTextColumn? {
        matrix.columns.first { $0.id == id }
    }

    /// The columns an assistant can propose for: the group name only when
    /// there's a group, each product's once App Store Connect gave its id.
    var columns: [InAppTextColumn] {
        matrix.columns.filter(canWrite)
    }

    /// Empty texts an assistant could propose, in every listed locale.
    var missingCount: Int {
        matrix.displayLocales.reduce(0) { count, locale in
            count + columns.count { matrix.value($0, in: locale).isEmpty }
        }
    }

    private func canWrite(_ column: InAppTextColumn) -> Bool {
        guard let productID = column.productID else { return content.groupID != nil }
        return content.productResourceIDs[productID] != nil
    }

    /// The tool result for `get_in_app_texts`: the columns with their
    /// limits, then each locale's texts, App Store Connect's where a queued
    /// change differs (`live`), and what's still empty.
    func json(locales codes: [String]?) throws -> JSONValue {
        let locales = try codes.map { try $0.map(locale(code:)) } ?? matrix.displayLocales
        return [
            "appId": .string(app.id),
            "app": .string(app.name),
            "primaryLocale": .string(matrix.primaryLocale.code),
            "hasSubscriptionGroup": .bool(content.groupID != nil),
            "columns": .array(columns.map(Self.json)),
            "versions": .array(versionsJSON),
            "locales": .array(locales.map(json)),
        ]
    }

    /// Each owner's newest texts version (API 4.4.1) and where a push
    /// writes: that version, a new draft, or the pre-4.4.1 localizations.
    private var versionsJSON: [JSONValue] {
        builder.owners.compactMap { owner in
            guard owner.resourceID != nil else { return nil }
            var json: [String: JSONValue] = ["owner": .string(owner.productID ?? "group")]
            if let latest = content.latestVersions[owner.key] {
                if let version = latest.version { json["version"] = .int(version) }
                if let state = latest.state { json["state"] = .string(state) }
            }
            json["writesTo"] = switch builder.write(for: owner) {
            case .legacy: "legacy localizations"
            case .version: "editable version"
            case .draft: "new draft version"
            }
            return .object(json)
        }
    }

    private static func json(_ column: InAppTextColumn) -> JSONValue {
        var json: [String: JSONValue] = [
            "id": .string(column.id),
            "title": .string(column.title),
            "field": .string(column.field.isDescription ? "description" : "name"),
            "limit": ["max": .int(column.field.limit.maximum), "unit": "characters"],
        ]
        if let productID = column.productID { json["productId"] = .string(productID) }
        json["kind"] = switch column.field {
        case .subscriptionGroupName: "subscriptionGroup"
        case .subscriptionName, .subscriptionDescription: "subscription"
        case .purchaseName, .purchaseDescription: "inAppPurchase"
        }
        return .object(json)
    }

    private func json(_ locale: StoreLocale) -> JSONValue {
        var texts: [String: JSONValue] = [:]
        var live: [String: JSONValue] = [:]
        var missing: [JSONValue] = []
        for column in columns {
            let draft = matrix.draft(column, in: locale)
            if draft.local.isEmpty { missing.append(.string(column.id)) } else { texts[column.id] = .string(draft.local) }
            if draft.isPending { live[column.id] = .string(draft.remote) }
        }
        var json: [String: JSONValue] = ["code": .string(locale.code), "name": .string(locale.name), "texts": .object(texts)]
        if !live.isEmpty { json["live"] = .object(live) }
        if !missing.isEmpty { json["missing"] = .array(missing) }
        return .object(json)
    }

    private func locale(code: String) throws -> StoreLocale {
        guard let locale = StoreLocaleCatalog.locale(code: code) else {
            throw MCPToolError.notFound(String(localized: "“\(code)” isn’t an App Store Connect locale code."))
        }
        return locale
    }

    // MARK: - Proposing

    /// An assistant's text for one cell, validated like an edit in In-App
    /// Texts. A cell the person changed themselves is refused, not
    /// overwritten: their change waits in Review & Push.
    mutating func propose(_ text: String, column columnID: String, locale code: String, by client: String) -> Outcome {
        guard !content.isEmpty else {
            return .refused(reason: String(localized: "\(app.name) has no subscriptions or in-app purchases."))
        }
        guard let column = column(id: columnID) else {
            let known = columns.map(\.id).joined(separator: ", ")
            return .refused(reason: String(localized: "\(app.name) has no column “\(columnID)”. Its columns are \(known)."))
        }
        guard canWrite(column) else {
            return .refused(reason: String(localized: "\(app.name) has no subscription group in App Store Connect yet."))
        }
        guard let locale = StoreLocaleCatalog.locale(code: code) else {
            return .refused(reason: String(localized: "“\(code)” isn’t an App Store Connect locale code."))
        }
        switch ListingFieldValidator.validate(text, for: column.field) {
        case let .overLimit(count, limit):
            return .refused(
                reason: String(localized: "Over the limit: \(count) of \(limit.maximum) characters. Fix it and propose again."),
                count: count,
                limit: limit
            )
        case .empty:
            return .refused(reason: String(localized: "The text is empty. Propose the text itself."))
        case .valid, .invalidURL:
            break
        }
        let draft = matrix.draft(column, in: locale)
        if draft.isPending, draft.proposedBy == nil, draft.local != text {
            return .refused(reason: String(localized: "The person already changed this text to “\(draft.local)”; it waits in Review & Push. Leave it to them."))
        }
        guard case .queued = matrix.propose(text, for: column, in: locale, by: client) else { return .unchanged }
        touched.append(Cell(column: column, locale: locale))
        return .queued
    }

    /// Queues the proposed cells and returns each one's change, by
    /// `Cell.key`. A cell proposed back to App Store Connect's text leaves
    /// the queue and has no change.
    func commit(to queue: ChangeQueue) -> [String: PendingChange] {
        let desired = builder.changes(for: matrix)
        let existing = Dictionary(queue.changes(for: app.id, section: .storePage).filter(builder.owns).map { ($0.id, $0) }) { first, _ in first }
        var committed: [String: PendingChange] = [:]
        var upserts: [PendingChange] = []
        for cell in touched where committed[cell.key] == nil {
            let candidates = builder.changeIDs(for: cell.column, in: cell.locale)
            guard var change = desired.first(where: { candidates.contains($0.id) }) else {
                queue.discard(ids: candidates)
                continue
            }
            if let old = existing[change.id] { change.createdAt = old.createdAt }
            committed[cell.key] = change
            if !upserts.contains(where: { $0.id == change.id }) { upserts.append(change) }
        }
        queue.upsert(contentsOf: upserts)
        return committed
    }
}
