//
//  ScreenshotStudioModel+RunChoice.swift
//  AppLocalizer
//

import Foundation

/// The plan's "What this run makes": the preset, each row's line, the
/// languages and captures choices, and what the run makes in one sentence.
extension ScreenshotStudioModel {
    // MARK: - Presets

    func runPreset(_ plan: AutopilotPlan) -> AutopilotRunPreset {
        AutopilotRunPreset.matching(plan, devices: planDevices(plan))
    }

    func applyPreset(_ preset: AutopilotRunPreset) {
        guard let plan = run?.plan else { return }
        let devices = planDevices(plan)
        let canReuse = run?.keptFrom != nil
        updatePlan { preset.apply(to: &$0, devices: devices, canReuse: canReuse) }
        if preset == .everything, devices.contains(.visionPro) { setPlans(.visionPro, true) }
    }

    // MARK: - Rows

    func setMakesScreenshots(_ makes: Bool) {
        updatePlan { $0.runChoice.makesScreenshots = makes }
    }

    /// The App Preview row's device cell.
    func setPreviews(_ display: ScreenshotDisplayType, _ isOn: Bool) {
        updatePlan { plan in
            var displays = plan.previewDisplays
            displays.removeAll { $0 == display }
            if isOn { displays.append(display) }
            plan.runChoice.previewDisplays = AutopilotExtras.previewDisplays.filter(displays.contains)
        }
    }

    /// "17 screens per language · devices left out keep what’s live", or
    /// "Off · the live screenshots stay as they are".
    func screenshotsRowDetail(_ plan: AutopilotPlan) -> String {
        guard plan.makesScreenshots else { return String(localized: "Off · the live screenshots stay as they are") }
        let count = plan.screensPerLanguage
        let screens = count == 1 ? String(localized: "1 screen per language") : String(localized: "\(count) screens per language")
        let leftOut = planDevices(plan).contains { !plan.displayTypes.contains($0) }
        return leftOut ? screens + " · " + String(localized: "devices left out keep what’s live") : screens
    }

    func appPreviewRowDetail(_ plan: AutopilotPlan) -> String {
        plan.alsoMakes.makesAppPreview
            ? String(localized: "15–30 s from Simulator recordings, styled in the chosen direction")
            : String(localized: "Off · any live App Preview stays")
    }

    func artworkRowDetail(_ plan: AutopilotPlan) -> String {
        plan.alsoMakes.makesArtwork
            ? String(localized: "App Store page artwork · iOS 27 and iPadOS 27")
            : String(localized: "Off · any live artwork stays")
    }

    /// "15 languages", "English (U.S.)".
    func runLanguagesTitle(_ plan: AutopilotPlan) -> String {
        let count = plan.localeCodes.count
        guard count == 1 else { return String(localized: "\(count) languages") }
        return StoreLocaleCatalog.locale(code: plan.localeCodes[0])?.name ?? plan.localeCodes[0]
    }

    // MARK: - Languages

    /// "All 15", "English (U.S.) only", "Choose…".
    func languageModeTitle(_ mode: AutopilotLanguageMode, plan: AutopilotPlan) -> String {
        switch mode {
        case .all:
            let count = plan.storeLocaleCodes.count + (plan.runChoice.languages == .all ? plan.addedLocaleCodes.count : 0)
            return String(localized: "All \(count)")
        case .primary:
            let name = StoreLocaleCatalog.locale(code: plan.primaryLocale)?.name ?? plan.primaryLocale
            return String(localized: "\(name) only")
        case .chosen:
            return String(localized: "Choose…")
        }
    }

    func setLanguageMode(_ mode: AutopilotLanguageMode) {
        updatePlan { $0.setLanguageMode(mode) }
    }

    func setChooses(_ code: String, _ chosen: Bool) {
        updatePlan { $0.setChooses(code, chosen) }
    }

    /// "Include Polish, Turkish and Hebrew (in the app, not on the App
    /// Store yet)"; nil when the app has none.
    func includeNewLanguagesTitle(_ plan: AutopilotPlan) -> String? {
        let codes = plan.newLocaleCodes ?? []
        guard !codes.isEmpty else { return nil }
        let names = codes.map { StoreLocaleCatalog.locale(code: $0)?.shortName ?? $0 }.formatted(.list(type: .and))
        return String(localized: "Include \(names) (in the app, not on the App Store yet)")
    }

    // MARK: - Captures

    /// Whether the Captures choice matters: the run makes screenshots or
    /// artwork from captures.
    func capturesMatter(_ plan: AutopilotPlan) -> Bool {
        plan.makesScreenshots || !plan.artworkTargets.isEmpty
    }

    /// "Reuse Oct 28 captures"; nil when there's nothing to reuse.
    var reuseTitle: String? {
        run?.keptDate.map { String(localized: "Reuse \($0) captures") }
    }

    func setReusesCaptures(_ reuses: Bool) {
        updatePlan { $0.runChoice.reusesCaptures = reuses }
    }

    /// What capturing again or reusing means for this run.
    func capturesNote(_ plan: AutopilotPlan, client: String) -> String {
        let version = screenshots.context.version.versionString
        guard capturesMatter(plan) else {
            // A scene needs no captures.
            if !plan.artworkKinds.isEmpty {
                return plan.previewDisplays.isEmpty
                    ? String(localized: "Not needed: the artwork shows no app screens.")
                    : String(localized: "Not needed: the artwork shows no app screens; the App Preview is recorded either way.")
            }
            return plan.previewDisplays.isEmpty
                ? String(localized: "Not needed: this run makes no screenshots or artwork.")
                : String(localized: "Not needed: this run makes no screenshots or artwork; the App Preview is recorded either way.")
        }
        guard plan.reusesCaptures, let run, let kept = run.keptFrom, let date = run.keptDate else {
            return String(localized: "\(client) runs this build and captures again, so the screens match \(version).")
        }
        let devices = kept.displayTypes.map(\.shortTitle).formatted(.list(type: .and))
        let languages = kept.localeCount == 1 ? String(localized: "1 language") : String(localized: "\(kept.localeCount) languages")
        var text = kept.hasPicks
            ? String(localized: "Version \(kept.versionString) · \(devices) in \(languages), with your picks.")
            : String(localized: "Version \(kept.versionString) · \(devices) in \(languages).")
        text += " " + String(localized: "Faster, but shows the app as it was on \(date).")
        let uncovered = plan.runDisplays.filter { !kept.displayTypes.contains($0) && plan.makesScreenshots }
        if !uncovered.isEmpty {
            let names = uncovered.map(\.shortTitle).formatted(.list(type: .and))
            text += " " + (uncovered.count == 1
                ? String(localized: "\(names) has no earlier captures, so it’s captured now.")
                : String(localized: "\(names) have no earlier captures, so they’re captured now."))
        }
        if plan.makesScreenshots, plan.screens.contains(where: { $0.origin != nil }) {
            text += " " + String(localized: "New screens in the plan are captured now.")
        }
        if !plan.previewDisplays.isEmpty { text += " " + String(localized: "The App Preview is still recorded.") }
        return text
    }

    // MARK: - Summary

    /// "This run makes 255 screenshots for iPhone, iPad, Apple Watch and
    /// Apple Vision Pro in 15 languages. Everything else on the App Store
    /// stays as it is."
    func runSummaryText(_ plan: AutopilotPlan) -> String {
        guard !plan.makesNothing else { return String(localized: "Nothing selected. Turn on at least one row.") }
        return String(localized: "This run makes \(Self.runMakes(plan)). Everything else on the App Store stays as it is.")
    }

    /// "255 screenshots for iPhone and iPad, header and search artwork and
    /// an App Preview for iPhone in 15 languages (the App Preview in English
    /// (U.S.) only)".
    static func runMakes(_ plan: AutopilotPlan) -> String {
        var parts: [String] = []
        if plan.makesScreenshots {
            let count = plan.screensPerLanguage * plan.localeCodes.count
            parts.append(String(localized: "\(count) screenshots for \(plan.devicesTitle)"))
        }
        if !plan.artworkKinds.isEmpty { parts.append(plan.artworkMadeTitle) }
        if !plan.previewDisplays.isEmpty {
            let devices = plan.previewDisplays.map(\.shortTitle).formatted(.list(type: .and))
            parts.append(String(localized: "an App Preview for \(devices)"))
        }
        let primary = StoreLocaleCatalog.locale(code: plan.primaryLocale)?.name ?? plan.primaryLocale
        let onlyPreview = parts.count == 1 && !plan.previewDisplays.isEmpty
        let count = plan.localeCodes.count
        var tail: String
        if onlyPreview, plan.alsoMakes.previewLanguages == .primary {
            tail = String(localized: "in \(primary)")
        } else {
            tail = count == 1 ? String(localized: "in \(primary)") : String(localized: "in \(count) languages")
            if !onlyPreview, !plan.previewDisplays.isEmpty, plan.alsoMakes.previewLanguages == .primary, count > 1 {
                tail += " " + String(localized: "(the App Preview in \(primary) only)")
            }
        }
        return parts.formatted(.list(type: .and)) + " " + tail
    }
}
