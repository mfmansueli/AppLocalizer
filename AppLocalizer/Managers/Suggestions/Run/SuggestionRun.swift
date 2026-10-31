//
//  SuggestionRun.swift
//  AppLocalizer
//

import Foundation

/// Suggest Everything: one assistant suggesting every field of an app it
/// can. Suggest Everything… copies the prompt and waits; the assistant's
/// `begin_suggestions` announces the plan, which gives the total and the
/// fields still to come; `suggest_fields` with the run's id fills it in.
/// Items outside the plan are added to the total. The run finishes at the
/// plan's last item or `end_suggestions`; Stop Receiving keeps what arrived
/// and refuses the rest.
struct SuggestionRun: Identifiable, Hashable, Sendable {
    enum Phase: Hashable, Sendable {
        /// The prompt is copied; the assistant hasn't announced a plan.
        case waiting
        case running
        case finished
        /// Stop Receiving.
        case stopped
    }

    /// With nothing arriving for this long, the card says the assistant
    /// stopped sending.
    static let quietInterval: TimeInterval = 120

    /// "run_1": what the assistant passes back with each call.
    var id: String
    var appID: StoreApp.ID
    /// e.g. "Claude Code".
    var client: String
    /// What Suggest Everything… copied; empty when the assistant started
    /// on its own (`/mcp__applocalizer__suggest_all`).
    var prompt: String
    var phase: Phase
    /// The fields the assistant said it will suggest, in its order.
    var plan: [SuggestionTarget] = []
    /// Fields it sent with the run that weren't in the plan.
    var extras: [SuggestionTarget] = []
    var arrived: Set<SuggestionTarget> = []
    /// What arrived, for Accept All.
    var suggestionIDs: [FieldSuggestion.ID] = []
    var startedAt: Date
    var lastActivityAt: Date

    var total: Int { plan.count + extras.count }
    var received: Int { arrived.count }

    var isRunning: Bool { phase == .running }
    var isOver: Bool { phase == .finished || phase == .stopped }

    var fraction: Double {
        total > 0 ? min(1, Double(received) / Double(total)) : 0
    }

    /// Every planned field arrived.
    var isComplete: Bool {
        plan.allSatisfy(arrived.contains)
    }

    /// Nothing arrived for two minutes while it still runs.
    func isQuiet(at date: Date) -> Bool {
        isRunning && date.timeIntervalSince(lastActivityAt) >= Self.quietInterval
    }

    /// A planned field whose suggestion hasn't arrived, while the run goes on.
    func isComing(_ target: SuggestionTarget) -> Bool {
        isRunning && !arrived.contains(target) && plan.contains(target)
    }

    /// How many are still to come in `scopes`.
    func comingCount(in scopes: some Collection<SuggestionScope>) -> Int {
        guard isRunning else { return 0 }
        return plan.count { scopes.contains($0.scope) && !arrived.contains($0) }
    }

    func comingCount(on page: SuggestionPage) -> Int {
        guard isRunning else { return 0 }
        return plan.count { SuggestionPage($0.scope) == page && !arrived.contains($0) }
    }

    // MARK: - Arriving

    /// A field the assistant settled: planned, or sent with the run's id.
    /// `suggestionID` is nil when the field already held the value.
    mutating func noteArrival(of target: SuggestionTarget, suggestionID: FieldSuggestion.ID?, at date: Date) {
        if !plan.contains(target), !extras.contains(target) {
            extras.append(target)
        }
        arrived.insert(target)
        if let suggestionID, !suggestionIDs.contains(suggestionID) { suggestionIDs.append(suggestionID) }
        lastActivityAt = date
    }

    // MARK: - Text

    /// "Suggesting everything · 9 of 18".
    var progressText: String {
        String(localized: "Suggesting everything · \(received) of \(total)")
    }

    /// The card's title.
    var title: String {
        switch phase {
        case .waiting, .running: String(localized: "Suggesting everything")
        case .finished: String(localized: "Finished suggesting")
        case .stopped: String(localized: "Stopped receiving")
        }
    }

    /// Beside the title: "9 of 18", "18 suggestions", "12 suggestions of 18".
    var countText: String {
        switch phase {
        case .waiting, .running: String(localized: "\(received) of \(total)")
        case .finished where received == 1: String(localized: "1 suggestion")
        case .finished: String(localized: "\(received) suggestions")
        case .stopped: String(localized: "\(received) suggestions of \(total)")
        }
    }

    /// "Claude Code stopped sending · 12 of 18".
    var quietText: String {
        String(localized: "\(client) stopped sending · \(received) of \(total)")
    }

    /// The banner on a page: "Here: 2 of 3 arrived."
    func hereText(in scopes: some Collection<SuggestionScope>) -> String? {
        let here = (plan + extras).filter { scopes.contains($0.scope) }
        guard !here.isEmpty else { return nil }
        return String(localized: "Here: \(here.count(where: arrived.contains)) of \(here.count) arrived.")
    }

    /// The toast once it's over: "Claude Code sent 18 suggestions: Store
    /// Page 5 · General 1 · Age Rating 6 · Accessibility 5 · App Review 1."
    var finishedText: String {
        guard received > 0 else { return String(localized: "\(client) looked at everything and found nothing new to suggest.") }
        let areas = rows.filter { $0.arrived > 0 }.map { "\($0.page.title) \($0.arrived.formatted())" }.joined(separator: " · ")
        return received == 1
            ? String(localized: "\(client) sent 1 suggestion: \(areas).")
            : String(localized: "\(client) sent \(received) suggestions: \(areas).")
    }

    // MARK: - Rows

    /// One per page the run covers, in the pages' order.
    var rows: [SuggestionRunRow] {
        let targets = plan + extras
        return SuggestionPage.allCases.compactMap { page in
            let here = targets.filter { SuggestionPage($0.scope) == page }
            guard !here.isEmpty else { return nil }
            return SuggestionRunRow(page: page, detail: detail(of: here, on: page), arrived: here.count(where: arrived.contains), total: here.count)
        }
    }

    /// Per language or device ("German 0/1", or "German 1" once it's over),
    /// or the fields' names.
    private func detail(of targets: [SuggestionTarget], on page: SuggestionPage) -> String {
        guard page == .storePage || page == .accessibility else {
            return targets.map(SuggestionPage.fieldTitle).joined(separator: ", ")
        }
        var scopes: [SuggestionScope] = []
        for target in targets where !scopes.contains(target.scope) {
            scopes.append(target.scope)
        }
        return scopes.map { scope in
            let inScope = targets.filter { $0.scope == scope }
            let count = inScope.count(where: arrived.contains)
            let name = Self.name(of: scope)
            return isOver ? "\(name) \(count.formatted())" : "\(name) \(count.formatted())/\(inScope.count.formatted())"
        }
        .joined(separator: " · ")
    }

    /// "German", "Apple Watch".
    private static func name(of scope: SuggestionScope) -> String {
        switch scope {
        case let .storePage(code): StoreLocaleCatalog.locale(code: code)?.name ?? code
        case let .accessibility(family): DeviceFamily(rawValue: family)?.name ?? family
        case .appInformation: scope.title
        }
    }
}
