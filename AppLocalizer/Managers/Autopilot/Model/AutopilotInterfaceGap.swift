//
//  AutopilotInterfaceGap.swift
//  AppLocalizer
//

import Foundation

/// A device whose screens the app had captured in only some of the run's
/// languages before it: Lumen's iPad screens in 4 of 18. The other
/// languages showed the primary language's interface under their
/// captions; a run that captures each language captures them too, so Plan
/// says so and Review checks it.
struct AutopilotInterfaceGap: Codable, Hashable, Sendable {
    var displayType: ScreenshotDisplayType
    /// The run's languages it had captures of its own in.
    var capturedCount: Int
    /// The run's languages.
    var languageCount: Int

    /// The languages the run captures for the first time.
    var missingCount: Int { max(0, languageCount - capturedCount) }

    /// The devices whose sets lag behind iPhone's: iPad, iPhone Duo and
    /// Mac. Apple Watch shows bare screens, Apple Vision Pro its own
    /// windows.
    static let devices: [ScreenshotDisplayType] = [.iPad, .iPhoneDuo, .mac]

    /// The plan's iPad, iPhone Duo and Mac with captures in some of its
    /// languages but not all, when the run captures each language. A
    /// device with none at all is new to the set, not a gap.
    static func gaps(in plan: AutopilotPlan, captures: CaptureIndex) -> [AutopilotInterfaceGap] {
        guard plan.makesScreenshots, plan.capturesEachLanguage, plan.localeCodes.count > 1 else { return [] }
        let languages = Set(plan.localeCodes)
        return plan.displayTypes.filter(devices.contains).compactMap { display in
            let captured = languages.intersection(captures.localesWithOwnInterface(displayType: display)).count
            guard captured > 0, captured < languages.count else { return nil }
            return AutopilotInterfaceGap(displayType: display, capturedCount: captured, languageCount: languages.count)
        }
    }

    /// "iPad screens exist in only 4 languages", "iPad and Mac screens
    /// exist in only 4 languages", "iPad screens exist in only 4 languages
    /// and its Mac screens in 2": what the app had before the run.
    static func before(_ gaps: [AutopilotInterfaceGap], app: String) -> String {
        let counts = Set(gaps.map(\.capturedCount))
        if counts.count == 1, let count = counts.first {
            let devices = gaps.map(\.displayType.shortTitle).formatted(.list(type: .and))
            return count == 1
                ? String(localized: "\(app)’s \(devices) screens exist in only 1 language")
                : String(localized: "\(app)’s \(devices) screens exist in only \(count) languages")
        }
        let first = gaps[0]
        let lead = first.capturedCount == 1
            ? String(localized: "\(app)’s \(first.displayType.shortTitle) screens exist in only 1 language")
            : String(localized: "\(app)’s \(first.displayType.shortTitle) screens exist in only \(first.capturedCount) languages")
        let rest = gaps.dropFirst().map { gap in
            String(localized: "its \(gap.displayType.shortTitle) screens in \(gap.capturedCount)")
        }
        return ([lead] + rest).formatted(.list(type: .and))
    }

    /// "before, iPad screens existed in 4", "before, iPad screens existed
    /// in 4 and Mac screens in 2": Review's note on what the run filled.
    static func existed(_ gaps: [AutopilotInterfaceGap]) -> String {
        let counts = Set(gaps.map(\.capturedCount))
        if counts.count == 1, let count = counts.first {
            let devices = gaps.map(\.displayType.shortTitle).formatted(.list(type: .and))
            return String(localized: "before, \(devices) screens existed in \(count)")
        }
        let parts = gaps.enumerated().map { index, gap in
            index == 0
                ? String(localized: "before, \(gap.displayType.shortTitle) screens existed in \(gap.capturedCount)")
                : String(localized: "\(gap.displayType.shortTitle) screens in \(gap.capturedCount)")
        }
        return parts.formatted(.list(type: .and))
    }
}
