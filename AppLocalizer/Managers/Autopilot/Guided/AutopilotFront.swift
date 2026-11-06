//
//  AutopilotFront.swift
//  AppLocalizer
//

import Foundation

/// Which Autopilot the Screenshots section shows: the guided steps (say
/// what to make, see the plan, walk away, come back to choose and to
/// approve) or the classic sheet with every setting on one plan. Both run
/// the same engine; a run started in one can be opened in the other.
enum AutopilotFront: String, CaseIterable, Hashable, Sendable {
    case guided
    case classic

    var title: String {
        switch self {
        case .guided: String(localized: "Guided")
        case .classic: String(localized: "Classic")
        }
    }

    /// Settings → General's line under the choice.
    static let note = String(localized: """
    Guided asks what to make, shows the plan, and stops only to choose the look and to review. Classic shows every \
    setting on one plan and each stage on its own.
    """)
}
