//
//  AutopilotScreenDraft.swift
//  AppLocalizer
//

import Foundation

/// "+ Add a Screen…"'s form: a name is enough while the assistant works out
/// the steps; an empty caption is written by the assistant.
struct AutopilotScreenDraft: Hashable, Sendable {
    var name = ""
    var steps = ""
    var caption = ""
    var worksOutSteps = true

    /// Add Screen: a name, and the steps unless the assistant works them out.
    var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (worksOutSteps || !steps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    /// The screen it adds after the plan's iPhone and iPad screens.
    func screen(id: String) -> AutopilotScreen {
        AutopilotScreen(
            id: id, name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            steps: worksOutSteps ? "" : steps.trimmingCharacters(in: .whitespacesAndNewlines),
            caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            origin: .person, worksOutSteps: worksOutSteps ? true : nil
        )
    }
}
