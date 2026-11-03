//
//  AutopilotPickAttempt.swift
//  AppLocalizer
//

import Foundation

/// One of a screen's captures at Pick: the capture, how it ranked, and
/// whether it's the one used.
struct AutopilotPickAttempt: Hashable, Identifiable {
    var capture: AutopilotCapture
    /// 0 is the assistant's pick.
    var rank: Int
    var isUsed: Bool

    var id: String { capture.id }
    var isBest: Bool { rank == 0 }
}
