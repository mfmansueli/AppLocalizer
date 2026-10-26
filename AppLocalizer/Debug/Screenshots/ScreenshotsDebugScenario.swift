//
//  ScreenshotsDebugScenario.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The sample data a Screenshots DEBUG scene starts from.
enum ScreenshotsDebugScenario: Sendable {
    /// Template v4, twelve localized locales, eight live: "40 not pushed ·
    /// 2 checks failed".
    case standard
    /// A brand font without Thai or Vietnamese, both added to the scope,
    /// and an iPad capture in Korean's iPhone slot 4: "23 renders fail".
    case failedChecks
    /// Nothing imported yet.
    case noCaptures
    /// Captures from fastlane but no template: the starter picker.
    case noTemplate
}
#endif
