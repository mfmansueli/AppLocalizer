//
//  AutopilotDuoShot.swift
//  AppLocalizer
//

import Foundation

/// One of iPhone Duo's screenshots: the plan's screen it shows and the
/// captures it's made from (the inner display, the cover display, or both
/// side by side).
struct AutopilotDuoShot: Hashable, Sendable {
    /// The set slot whose screen and caption it carries.
    var screenSlot: Int
    /// One pose, or open then closed for a side-by-side image.
    var poses: [AutopilotDuoPose]

    var isPair: Bool { poses.count > 1 }
}
