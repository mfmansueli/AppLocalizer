//
//  GuidedStepState.swift
//  AppLocalizer
//

import Foundation

/// A step on the guided stepper: done (a checkmark), current, or still to
/// come.
enum GuidedStepState: Hashable, Sendable {
    case done
    case current
    case upcoming
}
