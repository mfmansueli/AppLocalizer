//
//  MCPListingDraft.swift
//  AppLocalizer
//

import Foundation

/// One app's store listing as an assistant sees it: App Store Connect's texts
/// for the newest editable version (else the live one) with everything
/// already queued laid on top, exactly as the Store Page shows it.
/// Proposals change the draft; `commit(to:)` queues them the way the Store
/// Page does, so an open Store Page picks them up from the queue.
@MainActor
struct MCPListingDraft {
    let app: StoreApp
    let content: StorePageContent
    let builder: ListingChangeBuilder
    private(set) var listing: StoreListing
    /// Fields a proposal changed since loading.
    private var touched: [ListingFieldKey] = []

    static func load(app identifier: String, in workspace: MCPWorkspace) async throws -> MCPListingDraft {
        let app = try await workspace.app(matching: identifier)
        let services = workspace.services.storePage
        let content: StorePageContent
        do {
            content = try await services.content(for: app, versionID: nil)
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t read \(app.name)’s store listing: \(error.localizedDescription)"))
        }
        let builder = ListingChangeBuilder(appID: app.id, ids: content.ids, versionString: content.version.versionString)
        let tags = MachineTranslationScope.tags(in: services.machineTranslations, appID: app.id, ids: content.ids)
        var listing = content.listing(machineTranslated: tags)
        builder.apply(workspace.changes.changes(for: app.id, section: .storePage), to: &listing, machineTranslated: tags)
        return MCPListingDraft(app: app, content: content, builder: builder, listing: listing)
    }

    // MARK: - Reading

    /// The version these texts belong to, for tool results.
    var versionJSON: JSONValue {
        let version = listing.version
        return [
            "versionString": .string(version.versionString),
            "state": .string(version.state.title),
            "editable": .bool(version.isEditable),
        ]
    }

    /// The locales an assistant asked for, by code; every locale when nil.
    /// Unknown codes and locales the app doesn't have are refused.
    func locales(_ codes: [String]?) throws -> [StoreLocale] {
        guard let codes else { return listing.displayLocales }
        return try codes.map { code in
            guard let locale = StoreLocaleCatalog.locale(code: code), listing.contains(locale) else {
                let known = listing.displayLocales.map(\.code).joined(separator: ", ")
                throw MCPToolError.notFound(String(localized: "\(app.name) has no locale “\(code)”. Its locales are \(known)."))
            }
            return locale
        }
    }

    /// "Lumen Journal · version 1.4".
    var target: String {
        String(localized: "\(app.name) · version \(listing.version.versionString)")
    }

    /// "Lumen Journal · de-DE · Subtitle".
    func target(locale code: String, field: ListingField?) -> String {
        [app.name, code, field?.title].compactMap(\.self).joined(separator: " · ")
    }

    // MARK: - Proposing

    /// An assistant's text for one field, validated like an edit in the
    /// Store Page.
    mutating func propose(_ text: String, for field: ListingField, locale code: String, by client: String) -> ListingProposalOutcome {
        let outcome = listing.propose(text, for: field, localeCode: code, by: client)
        switch outcome {
        case .queued, .conflict:
            if let locale = StoreLocaleCatalog.locale(code: code) { touched.append(ListingFieldKey(locale, field)) }
        case .unchanged, .refused:
            break
        }
        return outcome
    }

    /// Queues the proposed fields and returns each one's change ID. A field
    /// proposed back to App Store Connect's value leaves the queue.
    func commit(to queue: ChangeQueue) -> [ListingFieldKey: PendingChange.ID] {
        let desired = builder.changes(for: listing)
        var ids: [ListingFieldKey: PendingChange.ID] = [:]
        var upserts: [PendingChange] = []
        for key in touched where ids[key] == nil {
            let candidates = [builder.changeID(for: key), builder.newLocaleChangeID(for: key.locale, at: key.field.level)]
            if let change = desired.first(where: { candidates.contains($0.id) }) {
                ids[key] = change.id
                if !upserts.contains(where: { $0.id == change.id }) { upserts.append(change) }
            } else {
                queue.discard(id: builder.changeID(for: key))
            }
        }
        queue.upsert(contentsOf: upserts)
        return ids
    }
}
