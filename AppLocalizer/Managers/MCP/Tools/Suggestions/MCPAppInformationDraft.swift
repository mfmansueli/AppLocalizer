//
//  MCPAppInformationDraft.swift
//  AppLocalizer
//

import Foundation

/// One app's General, Age Rating, Accessibility and App Review values as
/// an assistant sees them: App Store Connect's for the newest editable
/// version (else the live one), with everything already queued laid on
/// top, as App Information shows them. The demo password is never read.
@MainActor
struct MCPAppInformationDraft {
    let app: StoreApp
    let slots: AppInformationSlotValues

    var content: AppInformationContent { slots.content }
    var builder: AppInformationChangeBuilder { slots.builder }
    var general: GeneralValues { slots.general }

    /// Accessibility is read only when `includesAccessibility`; when it
    /// can't be read, its features can't take suggestions.
    static func load(app identifier: String, in workspace: MCPWorkspace, includesAccessibility: Bool = true) async throws -> MCPAppInformationDraft {
        let app = try await workspace.app(matching: identifier)
        let content: AppInformationContent
        do {
            content = try await workspace.services.appInformation.content(for: app, versionID: nil)
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t read \(app.name)’s app information: \(error.localizedDescription)"))
        }
        let accessibility = includesAccessibility ? try? await workspace.services.appInformation.accessibility(for: app) : nil
        let builder = AppInformationChangeBuilder(appID: app.id, ids: content.ids, versionString: content.version?.versionString)
        let changes = workspace.changes.changes(for: app.id, section: .appInformation)
        return MCPAppInformationDraft(
            app: app,
            slots: AppInformationSlotValues(content: content, accessibility: accessibility, builder: builder, changes: changes)
        )
    }

    /// The same values with `changes` queued instead.
    func with(changes: [PendingChange]) -> MCPAppInformationDraft {
        MCPAppInformationDraft(
            app: app,
            slots: AppInformationSlotValues(content: content, accessibility: slots.accessibility, builder: builder, changes: changes)
        )
    }

    /// The field's value as shown, as stored (categories by id).
    func value(_ field: AppInformationSuggestionField) -> String {
        slots.value(.field(field))
    }

    /// App Store Connect's value, before anything queued.
    func liveValue(_ field: AppInformationSuggestionField) -> String {
        slots.liveValue(.field(field))
    }

    /// Version-level fields of a version in review or live.
    func isLocked(_ field: AppInformationSuggestionField) -> Bool {
        field.isVersionLevel && !content.isVersionEditable
    }

    var versionJSON: JSONValue {
        guard let version = content.version else { return .null }
        return [
            "versionString": .string(version.versionString),
            "state": .string(version.state.title),
            "editable": .bool(version.isEditable),
        ]
    }

    /// "Lumen Journal · App Review · Notes".
    func target(_ field: AppInformationSuggestionField?) -> String {
        [app.name, field?.page.title, field?.title].compactMap(\.self).joined(separator: " · ")
    }
}
