//
//  TemplateEditorViewModel+History.swift
//  AppLocalizer
//

import Foundation

// The History popover and the Starter Templates sheet. Both make a new
// version, so nothing is ever lost.
extension TemplateEditorViewModel {
    /// One row of the History popover, newest first.
    struct HistoryRow: Identifiable, Hashable {
        var number: Int
        var note: String
        /// "Oct 12 · You".
        var detail: String
        var assistant: String?
        var isCurrent: Bool
        var canRestore: Bool

        var id: Int { number }
    }

    var historyRows: [HistoryRow] {
        guard let history else { return [] }
        let current = history.currentNumber
        return history.versions.reversed().map { version in
            let date = version.date.formatted(.dateTime.month(.abbreviated).day())
            return HistoryRow(
                number: version.number, note: note(for: version),
                detail: "\(date) · \(version.author.title)", assistant: version.assistant,
                isCurrent: version.number == current && !hasUnsavedEdits,
                canRestore: version.number != current || hasUnsavedEdits
            )
        }
    }

    /// The version's note, with " · pushed Oct 12" when renders went live
    /// while it was the current version.
    private func note(for version: TemplateVersion) -> String {
        let next = history?.versions.first { $0.number > version.number }?.date ?? .distantFuture
        let pushes = screenshots.document?.pushed.map(\.date).filter { $0 >= version.date && $0 < next } ?? []
        guard let pushed = pushes.max() else { return version.note }
        return String(localized: "\(version.note) · pushed \(pushed.formatted(.dateTime.month(.abbreviated).day()))")
    }

    /// Restore This Version: a new version from the old one. Unsaved edits
    /// are dropped.
    func restore(_ number: Int) async {
        guard var document = screenshots.document, var history = document.history else { return }
        history.restore(number, date: .now)
        document.history = history
        discardEdits()
        isHistoryPresented = false
        await screenshots.commit(document)
    }

    /// The sheet's button: "Start Over from This" for the starter the
    /// template came from, else "Switch to This".
    func starterButtonTitle(_ starter: TemplateStarter) -> String {
        template?.starter == starter ? String(localized: "Start Over from This") : String(localized: "Switch to This")
    }

    /// Switches templates as a new version; captions and captures stay.
    func switchStarter(_ starter: TemplateStarter) async {
        discardEdits()
        isStarterSheetPresented = false
        await screenshots.chooseStarter(starter)
    }

    /// The sheet's intro: "Every template renders all of Lumen’s languages
    /// and devices. Switching keeps captions and captures, and starts a new
    /// template version you can undo from History."
    var starterSheetNote: String {
        let title = templateTitle
        return String(
            localized: "Every template renders all of \(title)’s languages and devices. Switching keeps captions and captures, and starts a new template version you can undo from History."
        )
    }

    /// "Lumen" from "Lumen · Caption above device".
    var templateTitle: String {
        guard let name = template?.name else { return screenshots.app.name }
        return name.components(separatedBy: " · ").first ?? name
    }
}
