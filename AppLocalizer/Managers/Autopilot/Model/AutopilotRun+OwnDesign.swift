//
//  AutopilotRun+OwnDesign.swift
//  AppLocalizer
//

import Foundation

/// A run without a design project whose plan has the assistant design the
/// screenshot looks: they come from the app's own design (the project's
/// design docs, theme and icon) instead of AppLocalizer's starters colored
/// from the icon. Bruma's person asked to "follow the design we have on the
/// app", and the starters couldn't.
extension AutopilotRun {
    /// The assistant designs this run's looks from the app itself.
    var designsFromTheApp: Bool {
        designName == nil && designKind.usesDesignAI && plan.assistantDesignsLooks == true
    }

    /// Where the design comes from, for next_step's `how`.
    static let ownDesignHow = """
    design from the app's own design (there is no design project): aboutTheApp.look in the brief and the project's \
    design docs, theme tokens, fonts and icon, so each direction looks like it belongs to the app, never a generic starter
    """
}
