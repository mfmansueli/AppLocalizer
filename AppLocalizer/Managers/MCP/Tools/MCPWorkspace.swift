//
//  MCPWorkspace.swift
//  AppLocalizer
//

import Foundation

/// What assistant tools read and change: the open account's apps and
/// services, and the review queue their proposals go into. `MainView`
/// attaches it to `MCPServerController` while an account is open; without
/// one, every tool answers that AppLocalizer isn't connected.
@MainActor
struct MCPWorkspace {
    /// The account's name, e.g. "Northpier Studio", for log lines.
    var teamName: String
    var services: WorkspaceServices
    var changes: ChangeQueue
    var pricingModes: PricingModeStore
    /// Every app in the account, from the library when it has loaded.
    var apps: @MainActor () async throws -> [StoreApp]
    /// Settings → Translation's glossary and tone, read when a tool runs.
    var glossary: @MainActor () -> TranslationGlossary = { TranslationGlossary() }

    /// The app an assistant means: its Apple ID, bundle ID, SKU or name (case
    /// and accents ignored). A name may also be the start of one, when only
    /// one app starts with it.
    func app(matching identifier: String) async throws -> StoreApp {
        let apps = try await apps()
        let wanted = Self.normalized(identifier)
        if let exact = apps.first(where: { app in
            [app.id, app.bundleID, app.sku ?? "", app.name].contains { Self.normalized($0) == wanted }
        }) {
            return exact
        }
        let prefixed = apps.filter { Self.normalized($0.name).hasPrefix(wanted) }
        if prefixed.count == 1, let app = prefixed.first { return app }
        let names = apps.map(\.name).formatted(.list(type: .or))
        throw MCPToolError.notFound(String(localized: "No app matches “\(identifier)”. Use list_apps; the apps are \(names)."))
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
