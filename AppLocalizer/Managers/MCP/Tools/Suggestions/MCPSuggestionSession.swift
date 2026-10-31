//
//  MCPSuggestionSession.swift
//  AppLocalizer
//

import Foundation

/// One `suggest_fields` call at work: the app's Store Page and App
/// Information as the assistant sees them (loaded only when an item needs
/// them), and each item checked and put in the suggestion store, or with
/// `apply` queued as a change. `commit()` queues the Store Page's applied
/// values together, as the Store Page does. A language the app's project
/// has and the App Store page doesn't takes suggestions, never applied
/// values: its page is created only when the person adds it. `begin_suggestions` checks its
/// plan with the same session (`planned(_:)`).
@MainActor
struct MCPSuggestionSession {
    /// An item's result and its activity log line.
    struct Settled {
        var result: [String: JSONValue]
        var logLine: MCPToolOutcome.LogLine
    }

    let app: StoreApp
    let store: FieldSuggestionStore
    let context: MCPToolContext
    /// "Suggest and edit drafts" and `apply: true`.
    let applies: Bool
    /// The Suggest Everything run the items were sent with.
    let runID: SuggestionRun.ID?
    private(set) var listing: MCPListingDraft?
    private(set) var information: MCPAppInformationDraft?
    private var hasAppliedStoreText = false

    init(
        app: StoreApp,
        items: [MCPSuggestionItem],
        store: FieldSuggestionStore,
        context: MCPToolContext,
        applies: Bool,
        runID: SuggestionRun.ID? = nil
    ) async throws {
        self.app = app
        self.store = store
        self.context = context
        self.applies = applies
        self.runID = runID
        listing = items.contains { $0.area == .storePage } ? try await MCPListingDraft.load(app: app.id, in: context.workspace) : nil
        information = items.contains { $0.area == .appInformation }
            ? try await MCPAppInformationDraft.load(
                app: app.id,
                in: context.workspace,
                includesAccessibility: items.contains { $0.page.flatMap(SuggestFieldsTool.page(named:)) == .accessibility }
            )
            : nil
    }

    /// A `version` argument must be the one being prepared.
    func check(version: String?) throws {
        if let listing { try SuggestFieldsTool.check(version: version, against: listing.listing.version.versionString, app: app.name) }
        if let shown = information?.content.version?.versionString { try SuggestFieldsTool.check(version: version, against: shown, app: app.name) }
    }

    mutating func suggest(_ item: MCPSuggestionItem) -> Settled {
        var result: [String: JSONValue] = ["field": .string(item.field)]
        switch item.area {
        case .storePage: result["locale"] = item.locale.map(JSONValue.string) ?? .null
        case .appInformation:
            result["page"] = item.page.map(JSONValue.string) ?? .null
            if let device = item.device { result["device"] = .string(device) }
        }
        let target = target(of: item)
        do {
            let settled = switch item.area {
            case .storePage: try suggestStoreText(item)
            case .appInformation: try suggestInformation(item)
            }
            result.merge(settled) { _, new in new }
            let outcome: MCPCallOutcome = result["status"] == "unchanged" ? .read : .proposed
            return Settled(result: result, logLine: MCPToolOutcome.LogLine(target: target, outcome: outcome))
        } catch {
            result.merge(error.json) { _, new in new }
            return Settled(result: result, logLine: MCPToolOutcome.LogLine(target: target, outcome: .refused, reason: error.reason))
        }
    }

    /// Queues the Store Page values `apply` wrote.
    func commit() {
        guard hasAppliedStoreText, let listing else { return }
        _ = listing.commit(to: context.workspace.changes)
    }

    // MARK: - Store Page

    private mutating func suggestStoreText(_ item: MCPSuggestionItem) throws(MCPSuggestionRefusal) -> [String: JSONValue] {
        let (field, locale) = try storeTarget(of: item)
        var result: [String: JSONValue] = ["field": .string(field.rawValue)]
        if listing?.listing.value(field, in: locale) == item.value {
            result["status"] = "unchanged"
            noteSettled(.storePage(locale, field))
        } else if applies, var draft = listing, draft.listing.contains(locale) {
            _ = draft.propose(item.value, for: field, locale: locale.code, by: context.clientName)
            listing = draft
            hasAppliedStoreText = true
            result["status"] = "applied"
            noteSettled(.storePage(locale, field))
        } else {
            result.merge(add(item.value, for: .storePage(locale, field), item: item)) { _, new in new }
        }
        // Even with apply: only the person creates a page.
        if listing?.isNewLanguage(locale) == true {
            result["note"] = .string(String(localized: """
            \(locale.name) isn’t on the App Store yet: this shows in its own tab of the Store Page, and its page is created only when the person adds it and pushes.
            """))
        }
        return result
    }

    /// The field and language an item is for, and its value checked like an
    /// edit.
    private func storeTarget(of item: MCPSuggestionItem) throws(MCPSuggestionRefusal) -> (ListingField, StoreLocale) {
        let (field, locale) = try storeField(of: item)
        switch ListingFieldValidator.validate(item.value, for: field) {
        case let .overLimit(count, limit): throw .overLimit(count: count, limit: limit)
        case .invalidURL: throw .invalidValue(String(localized: "Not a full https:// URL."))
        case .empty: throw .invalidValue(String(localized: "The value is empty."))
        case .valid: return (field, locale)
        }
    }

    /// The field and language an item names, if the assistant may suggest
    /// it now.
    private func storeField(of item: MCPSuggestionItem) throws(MCPSuggestionRefusal) -> (ListingField, StoreLocale) {
        guard let listing = listing?.listing else { throw .invalidValue(String(localized: "The Store Page couldn’t be read.")) }
        guard let field = ListingField.matching(item.field) else { throw .unknownField(item.field, known: ListingField.mcpNames) }
        guard let code = item.locale else { throw .unknownLocale(String(localized: "Store Page suggestions need a locale, e.g. en-US.")) }
        guard let draft = self.listing, let locale = StoreLocaleCatalog.locale(code: code), listing.contains(locale) || draft.isNewLanguage(locale) else {
            throw .unknownLocale(self.listing?.unknownLocaleMessage(code) ?? code)
        }
        guard context.allows(.storeText) else { throw .notPermitted(.storeText) }
        guard listing.canEdit(field) else { throw .locked(version: listing.version.versionString) }
        return (field, locale)
    }

    // MARK: - App Information

    private mutating func suggestInformation(_ item: MCPSuggestionItem) throws(MCPSuggestionRefusal) -> [String: JSONValue] {
        let (slot, value, draft) = try informationTarget(of: item)
        var result = Self.json(slot)
        let source = ChangeSource.assistant(client: context.clientName)
        if draft.slots.value(slot) == value {
            result["status"] = "unchanged"
            noteSettled(slot.target)
        } else if applies, let written = draft.slots.change(slot, to: value, source: source, confirmed: false) {
            let changes = context.workspace.changes
            if let change = written.change { changes.upsert(change) } else { changes.discard(id: written.id) }
            // A device's next feature builds on this one.
            information = draft.with(changes: changes.changes(for: app.id, section: .appInformation))
            result["status"] = "applied"
            result["changeId"] = .string(written.id)
            noteSettled(slot.target)
        } else {
            result.merge(add(value, for: slot.target, item: item)) { _, new in new }
        }
        return result
    }

    /// The field, question or feature an item is for and its value as
    /// stored, checked like an edit on the page.
    private func informationTarget(
        of item: MCPSuggestionItem
    ) throws(MCPSuggestionRefusal) -> (AppInformationSuggestionSlot, String, MCPAppInformationDraft) {
        let (slot, draft) = try informationSlot(of: item)
        guard case let .field(field) = slot else {
            guard let value = slot.normalized(item.value) else {
                throw .invalidAnswer(String(localized: "“\(item.value)” isn’t an answer to \(item.field). The answers are \(slot.choiceList)."))
            }
            return (slot, value, draft)
        }
        guard let value = field.normalized(item.value), !value.isEmpty || field.isPicked else {
            throw .invalidValue(field.isPicked
                ? String(localized: "“\(item.value)” isn’t one of the choices get_app_information lists for \(field.rawValue).")
                : String(localized: "The value is empty."))
        }
        if let limit = field.limit, value.count > limit { throw .overLimit(count: value.count, limit: ListingTextLimit(limit)) }
        if field == .release, value == ReleaseOption.scheduled.rawValue, draft.general.earliestReleaseDate == nil {
            throw .invalidValue(String(localized: "“On a date” needs a date, which the person picks in AppLocalizer."))
        }
        return (slot, value, draft)
    }

    /// The field, question or feature an item names, if the assistant may
    /// suggest it now.
    private func informationSlot(of item: MCPSuggestionItem) throws(MCPSuggestionRefusal) -> (AppInformationSuggestionSlot, MCPAppInformationDraft) {
        guard let draft = information else { throw .invalidValue(String(localized: "App Information couldn’t be read.")) }
        let slot = try Self.slot(of: item, in: draft)
        guard context.allows(.appInformation) else { throw .notPermitted(.appInformation) }
        switch slot {
        case let .field(field):
            guard !draft.isLocked(field) else { throw .locked(version: draft.content.version?.versionString ?? "") }
        case .ageRating, .accessibility:
            guard draft.slots.canSuggest(slot) else {
                throw .invalidValue(String(localized: "App Store Connect has no age rating questionnaire for \(app.name) yet."))
            }
        }
        return (slot, draft)
    }

    /// What an item names: a General or App Review field (on any page when
    /// it names none), an Age Rating question, or a feature on the device
    /// it names (the only one, when the app has one).
    private static func slot(of item: MCPSuggestionItem, in draft: MCPAppInformationDraft) throws(MCPSuggestionRefusal) -> AppInformationSuggestionSlot {
        func named(_ name: String) -> Bool { name.caseInsensitiveCompare(item.field) == .orderedSame }
        let page = item.page.flatMap(SuggestFieldsTool.page(named:))
        switch page {
        case .ageRating:
            guard let question = AgeRatingQuestion.allCases.first(where: { named($0.rawValue) }) else {
                throw .unknownField(item.field, known: AgeRatingQuestion.allCases.map(\.rawValue))
            }
            return .ageRating(question)
        case .accessibility:
            let families = draft.slots.accessibilityFamilies
            guard !families.isEmpty else { throw .invalidValue(String(localized: "\(draft.app.name)’s accessibility couldn’t be read.")) }
            let devices = families.map(\.mcpName).joined(separator: ", ")
            guard let family = item.device.flatMap(DeviceFamily.init(mcpName:)) ?? (families.count == 1 ? families.first : nil) else {
                throw .invalidValue(String(localized: "Accessibility suggestions need a device: \(devices)."))
            }
            guard families.contains(family) else {
                throw .invalidValue(String(localized: "\(draft.app.name) doesn’t run on \(family.name). Its devices are \(devices)."))
            }
            guard let feature = family.features.first(where: { named($0.rawValue) }) else {
                throw .unknownField(item.field, known: family.features.map(\.rawValue))
            }
            return .accessibility(family, feature)
        default:
            let field = AppInformationSuggestionField.allCases.first { named($0.rawValue) }
            guard let field, page == nil || page == field.page else {
                throw .unknownField(item.field, known: AppInformationSuggestionField.allCases.filter { page == nil || $0.page == page }.map(\.rawValue))
            }
            return .field(field)
        }
    }

    /// The result's field, page and device, as MCP names them.
    private static func json(_ slot: AppInformationSuggestionSlot) -> [String: JSONValue] {
        var json: [String: JSONValue] = [
            "field": .string(slot.target.field),
            "page": .string(SuggestFieldsTool.mcpPageName(slot.scope.page?.rawValue ?? "")),
        ]
        if case let .accessibility(family, _) = slot { json["device"] = .string(family.mcpName) }
        return json
    }

    // MARK: - Plans

    /// A `begin_suggestions` entry: the field it names, or why the run
    /// leaves it out. A field the person changed and hasn't pushed is left
    /// alone.
    func planned(_ item: MCPSuggestionItem) -> Result<SuggestionTarget, MCPPlanSkip> {
        do throws(MCPSuggestionRefusal) {
            switch item.area {
            case .storePage:
                let (field, locale) = try storeField(of: item)
                if listing?.listing.draft(field, in: locale).isPending == true { return .failure(.changedByYou) }
                return .success(.storePage(locale, field))
            case .appInformation:
                let (slot, draft) = try informationSlot(of: item)
                if draft.slots.isPending(slot) { return .failure(.changedByYou) }
                return .success(slot.target)
            }
        } catch {
            return .failure(.refused(error))
        }
    }

    // MARK: - Helpers

    /// Into the suggestion store: queued, replaced or unchanged, and its id.
    private func add(_ value: String, for target: SuggestionTarget, item: MCPSuggestionItem) -> [String: JSONValue] {
        let added = store.add(
            appID: app.id,
            target: target,
            value: value,
            reason: item.reason,
            source: .assistant(client: context.clientName),
            evidence: item.evidence,
            runID: runID
        )
        return ["status": .string(added.outcome.rawValue), "id": .string(added.suggestion.id)]
    }

    /// A field that needed no suggestion counts toward the run.
    private func noteSettled(_ target: SuggestionTarget) {
        store.noteSettled(target, appID: app.id, source: .assistant(client: context.clientName), runID: runID)
    }

    /// "Lumen Journal · de-DE · Subtitle", "Lumen Journal · App Review ·
    /// Notes", "Lumen Journal · Accessibility · Apple Watch · VoiceOver".
    private func target(of item: MCPSuggestionItem) -> String {
        switch item.area {
        case .storePage:
            return [app.name, item.locale, ListingField.matching(item.field)?.title ?? item.field].compactMap(\.self).joined(separator: " · ")
        case .appInformation:
            guard let slot = information.flatMap({ try? Self.slot(of: item, in: $0) }) else { return [app.name, item.field].joined(separator: " · ") }
            return [app.name, slot.scope.title, slot.title].joined(separator: " · ")
        }
    }
}
