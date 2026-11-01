//
//  AutopilotProblemResolution.swift
//  AppLocalizer
//

import Foundation

/// What the person did about a problem.
enum AutopilotProblemResolution: String, Codable, Hashable, Sendable {
    /// Take the fix and capture again; the fix joins the plan.
    case retryWithFix
    /// The primary language's capture goes under this language's caption.
    case usePrimaryCapture
    /// The person uploaded the screen by hand.
    case uploadedByHand
    /// A later capture arrived for the screen.
    case captured
    /// The person left the device out of this run.
    case leftOut
}
