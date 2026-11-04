//
//  AutopilotRunChoice.swift
//  AppLocalizer
//

import Foundation

/// The plan's "What this run makes", beyond "Also make": whether the run
/// makes screenshots, whether it captures again or reuses the last run's
/// captures and picks, the App Preview's devices and the languages. What a
/// run leaves out stays live on the App Store as it is.
struct AutopilotRunChoice: Codable, Hashable, Sendable {
    /// The Screenshots row. Off, the live screenshots stay as they are and
    /// the run makes only the header and search artwork, the App Preview,
    /// or both.
    var makesScreenshots = true
    /// Captures: reuse the last run's captures and picks instead of
    /// capturing again. What they don't cover (a new screen, a device they
    /// didn't have) is captured anyway.
    var reusesCaptures = false
    /// The App Preview row's devices (iPhone, iPad); nil follows the
    /// screenshots' devices.
    var previewDisplays: [ScreenshotDisplayType]?
    /// Every language, the primary only, or the ones chosen.
    var languages: AutopilotLanguageMode = .all
    /// The App Store's languages when the run was planned, kept while the
    /// run has fewer, so All brings them back; nil while it has all.
    var storeLocaleCodes: [String]?
    /// The iPhone Duo row: the inner display, the cover display or both;
    /// nil is the inner display.
    var duoScreens: AutopilotDuoScreens?
    /// With both: side by side in each screenshot, or separate ones; nil
    /// is side by side.
    var duoBoth: AutopilotDuoBoth?
    /// Screenshot style: the design source's own directions, one from each
    /// picked gallery template, or the current template kept; nil (plans
    /// from before) is the design source's own.
    var shotStyle: AutopilotShotStyle?
    /// The gallery templates picked for Screenshot style's From templates,
    /// by name, in order (up to 3).
    var shotTemplates: [String]?
}
