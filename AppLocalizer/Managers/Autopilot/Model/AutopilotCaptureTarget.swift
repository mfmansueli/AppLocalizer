//
//  AutopilotCaptureTarget.swift
//  AppLocalizer
//

import Foundation

/// One screen on one device in one language; on iPhone Duo, in one pose
/// (a plan showing both displays captures each screen twice).
struct AutopilotCaptureTarget: Codable, Hashable, Sendable {
    var screenID: String
    var displayType: ScreenshotDisplayType
    var locale: String
    /// iPhone Duo's open (inner display) or closed (cover display); nil on
    /// every other device, and in runs from before.
    var duoPose: AutopilotDuoPose?
}
