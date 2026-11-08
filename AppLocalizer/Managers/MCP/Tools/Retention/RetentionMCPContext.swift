//
//  RetentionMCPContext.swift
//  AppLocalizer
//

import Foundation

/// One app's retention messages and offers as the retention tools read
/// them: what Pricing → Retention shows, with Review & Push's proposals and
/// the edits kept since on top.
@MainActor
struct RetentionMCPContext {
    let app: StoreApp
    let content: RetentionContent
    let messages: [RetentionMessage]
    let offers: [RetentionOffer]
    let queue: ChangeQueue
    let store: RetentionDraftStore

    static func load(app identifier: String, in workspace: MCPWorkspace, store: RetentionDraftStore) async throws -> RetentionMCPContext {
        let catalog = try await MCPPriceCatalog.load(app: identifier, in: workspace)
        let subscriptions = RetentionSubscription.all(in: catalog.catalog)
        guard !subscriptions.isEmpty else {
            throw MCPToolError.unavailable(String(localized: """
            \(catalog.app.name) has no auto-renewable subscriptions, and retention messages are for subscriptions. \
            Propose one with propose_subscription first.
            """))
        }
        let content: RetentionContent
        do {
            content = try await workspace.services.retention.content(for: catalog.app, subscriptions: subscriptions)
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t read \(catalog.app.name)’s retention messages: \(error.localizedDescription)"))
        }
        let working = RetentionWorkingSet(appID: catalog.app.id, content: content, queue: workspace.changes, store: store)
        return RetentionMCPContext(
            app: catalog.app, content: content, messages: working.messages, offers: working.offers, queue: workspace.changes, store: store
        )
    }

    /// Builds changes against these messages and offers, with `message` in
    /// its place (or added).
    func builder(with message: RetentionMessage? = nil) -> RetentionChangeBuilder {
        var current = content
        current.messages = messages
        if let message {
            if let index = current.messages.firstIndex(where: { $0.id == message.id }) {
                current.messages[index] = message
            } else {
                current.messages.append(message)
            }
        }
        current.offers = offers
        return RetentionChangeBuilder(app: app, content: current)
    }

    // MARK: - Finding

    /// A message by its id (App Store Connect's or a new one's) or name.
    func message(matching identifier: String) -> RetentionMessage? {
        let wanted = Self.normalized(identifier)
        return messages.first { $0.id == identifier || $0.remote?.messageID == identifier }
            ?? messages.first { Self.normalized($0.referenceName) == wanted }
    }

    /// A subscription by its Apple ID, product ID or name ("Lumen Plus
    /// Monthly", or just "Monthly").
    func subscription(matching identifier: String) -> RetentionSubscription? {
        let wanted = Self.normalized(identifier)
        return content.subscriptions.first { [$0.id, $0.productID, $0.name].map(Self.normalized).contains(wanted) }
            ?? content.subscriptions.first { Self.normalized($0.shortName) == wanted }
    }

    func requireSubscription(_ identifier: String) throws -> RetentionSubscription {
        guard let subscription = subscription(matching: identifier) else {
            let names = content.subscriptions.map { "\($0.name) (\($0.id))" }.formatted(.list(type: .or))
            throw MCPToolError.notFound(String(localized: "\(app.name) has no subscription “\(identifier)”. Its subscriptions are \(names)."))
        }
        return subscription
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Status

    func isQueued(_ message: RetentionMessage) -> Bool {
        queue.change(id: RetentionChangeBuilder.messageChangeID(appID: app.id, messageID: message.id)) != nil
    }

    /// "draft", "queued", "inReview", "live" or "rejected".
    func status(of message: RetentionMessage) -> String {
        if isQueued(message) { return "queued" }
        return switch message.remote?.status ?? .draft {
        case .draft: "draft"
        case .queued: "queued"
        case .inReview: "inReview"
        case .live: "live"
        case .rejected: "rejected"
        }
    }

    var target: String { "\(app.name) · \(String(localized: "Retention"))" }
}
