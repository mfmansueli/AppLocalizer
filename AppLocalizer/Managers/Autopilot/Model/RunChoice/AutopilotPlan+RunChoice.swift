//
//  AutopilotPlan+RunChoice.swift
//  AppLocalizer
//

import Foundation

/// "What this run makes" in the plan: screenshots or not, what's captured
/// without them, the devices the run uses, and the languages.
extension AutopilotPlan {
    /// The person's choice; screenshots, captured again, every language in
    /// runs from before.
    var runChoice: AutopilotRunChoice {
        get { choice ?? AutopilotRunChoice() }
        set { choice = newValue }
    }

    /// The run makes screenshots; off, the live ones stay as they are.
    var makesScreenshots: Bool { runChoice.makesScreenshots }

    /// Neither screenshots nor an extra: Start waits for one.
    var makesNothing: Bool { !makesScreenshots && artworkKinds.isEmpty && previewDisplays.isEmpty }

    /// Screenshots, but no screens yet (an app's first run): the assistant
    /// picks them once it's started, so the run still has everything to
    /// capture rather than nothing.
    var awaitsScreens: Bool { makesScreenshots && targets.isEmpty }

    /// The run uses the last run's captures and picks.
    var reusesCaptures: Bool { runChoice.reusesCaptures }

    /// Screenshot style: the design source's own directions unless the
    /// person chose templates or to keep the current one.
    var screenshotStyle: AutopilotShotStyle {
        get { runChoice.shotStyle ?? .free }
        set { runChoice.shotStyle = newValue }
    }

    /// The gallery templates picked for Screenshot style's From templates.
    var screenshotTemplates: [String] {
        get { runChoice.shotTemplates ?? [] }
        set { runChoice.shotTemplates = newValue }
    }

    /// What a direction brings, in Design's log: its template when the run
    /// makes screenshots; without them, its header and search (or the one
    /// 16:9 image), else the App Preview's look.
    var directionTitle: String {
        if makesScreenshots { return String(localized: "template") }
        guard alsoMakes.makesArtwork else { return String(localized: "App Preview look") }
        return alsoMakes.artworkSize.directionTitle
    }

    /// The screens the header and search artwork show: the search
    /// screen, on iPhone; none when the artwork is a scene.
    var artworkScreens: [AutopilotScreen] {
        let slots = Set(artworkKinds.flatMap { artworkSlots(for: $0) })
        return screens.enumerated().filter { slots.contains($0.offset) }.map(\.element)
    }

    /// Without screenshots, what the artwork needs captured: its screens on
    /// iPhone in the captured languages.
    var artworkTargets: [AutopilotCaptureTarget] {
        let screens = artworkScreens
        return capturedLocales.flatMap { locale in
            screens.map { AutopilotCaptureTarget(screenID: $0.id, displayType: .iPhone, locale: locale) }
        }
    }

    /// The devices the run captures or records on: the screenshots', the
    /// App Preview's, and iPhone for the artwork's captures.
    var runDisplays: [ScreenshotDisplayType] {
        var displays = makesScreenshots ? displayTypes : (artworkTargets.isEmpty ? [] : [.iPhone])
        for display in previewDisplays where !displays.contains(display) {
            displays.append(display)
        }
        return displays
    }

    // MARK: - Languages

    /// The App Store's languages, primary first, whatever the run has now.
    var storeLocaleCodes: [String] {
        runChoice.storeLocaleCodes ?? localeCodes.filter { newLocaleCodes?.contains($0) != true }
    }

    /// Every language the run can have: the App Store's, then the app's
    /// languages that aren't on it yet.
    var availableLocaleCodes: [String] {
        storeLocaleCodes + (newLocaleCodes ?? []).filter { !storeLocaleCodes.contains($0) }
    }

    /// All (with or without the new languages), the primary only, or the
    /// languages chosen so far.
    mutating func setLanguageMode(_ mode: AutopilotLanguageMode) {
        let store = storeLocaleCodes
        runChoice.languages = mode
        switch mode {
        case .all:
            // The new languages the run had stay in.
            let added = addedLocaleCodes
            runChoice.storeLocaleCodes = nil
            localeCodes = store + added
        case .primary:
            runChoice.storeLocaleCodes = store
            localeCodes = [primaryLocale]
        case .chosen:
            runChoice.storeLocaleCodes = store
        }
    }

    /// Choose…: adds or removes a language. The primary language stays:
    /// picks and the design start from it.
    mutating func setChooses(_ code: String, _ chosen: Bool) {
        guard code != primaryLocale else { return }
        if runChoice.languages != .chosen { setLanguageMode(.chosen) }
        let order = availableLocaleCodes
        var codes = Set(localeCodes)
        if chosen { codes.insert(code) } else { codes.remove(code) }
        localeCodes = order.filter(codes.contains)
    }
}
