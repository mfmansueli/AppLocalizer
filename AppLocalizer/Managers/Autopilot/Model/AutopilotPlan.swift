//
//  AutopilotPlan.swift
//  AppLocalizer
//

import Foundation

/// What a run captures and how: the screens, devices and languages, the
/// simulator setup, and where it stops for the person.
struct AutopilotPlan: Codable, Hashable, Sendable {
    /// iPhone's and iPad's screens: the set's slots.
    var screens: [AutopilotScreen]
    /// iPhone 6.9″ always; iPad 13″, Apple Watch and Apple Vision Pro when
    /// the app runs there.
    var displayTypes: [ScreenshotDisplayType]
    /// Apple Watch's and Apple Vision Pro's own screens; nil in runs from
    /// before them.
    var deviceScreens: [AutopilotDeviceScreens]?
    /// Devices the person turned off. A device the app gains later joins
    /// the next plan unless it's here; nil when there are none.
    var leftOutDevices: [ScreenshotDisplayType]?
    /// Every language of the version, primary first, then the languages the
    /// app supports that aren't on the App Store yet, when they're included.
    var localeCodes: [String]
    /// The app's languages the App Store page doesn't have yet; nil in runs
    /// from before them.
    var newLocaleCodes: [String]?
    var primaryLocale: String
    /// Launch the app in each language (`-AppleLanguages`); otherwise the
    /// primary language's captures are reused under translated captions.
    var capturesEachLanguage = true
    var simulator = AutopilotSimulatorSetup()
    /// Stop for the person to pick captures.
    var stopsToPick = true
    /// Stop for the person to choose the direction.
    var stopsToChoose = true
    /// Stop for the person to watch the App Preview; nil (runs from
    /// before) counts as yes. Use `stopsToWatchPreview`.
    var stopsToWatch: Bool?
    /// Where the steps came from, e.g. `LumenUITests/ScreenshotTests.swift`.
    var writtenFrom: String?
    /// Whether the assistant picks the screens; nil (runs from before)
    /// counts as yes. Use `choosesScreens`.
    var assistantChoosesScreens: Bool?
    /// "Also make · optional": header and search artwork, an App Preview.
    /// Nil in runs from before, which made neither. Use `alsoMakes`.
    var extras: AutopilotExtras?
    /// "What this run makes": screenshots or not, captures reused or not,
    /// the App Preview's devices, the languages. Nil in runs from before,
    /// which made screenshots. Use `runChoice`.
    var choice: AutopilotRunChoice?
    /// Without a design AI, the assistant designs the header and search
    /// concepts: the guided Look offers their style whatever the design
    /// project (MB Admin, with none, chose Go freely and got no header to
    /// choose). Nil in Classic plans, where AppLocalizer's starters draw
    /// them in the chosen look.
    var assistantDesignsArtwork: Bool?
    /// Without a design project, the assistant designs the screenshot
    /// looks too, from the app's own design as its project has it (design
    /// docs, theme, icon), instead of AppLocalizer's starters colored from
    /// the icon. Bruma's starters ignored the person's "follow the design
    /// we have on the app". Set by the guided defaults; nil in Classic
    /// plans and runs from before, which use the starters.
    var assistantDesignsLooks: Bool?

    /// Where the run's looks come from: the connected design project, else
    /// the assistant (as Claude Design, like the header concepts) when it
    /// designs them, else AppLocalizer's starters.
    func designKind(for project: DesignProject?) -> DesignProjectKind {
        if let project { return project.kind }
        return assistantDesignsLooks == true ? .claudeDesign : .none
    }

    /// Stop for the person to watch the App Preview before Review & Push,
    /// when the run makes one.
    var stopsToWatchPreview: Bool {
        get { stopsToWatch ?? true }
        set { stopsToWatch = newValue }
    }

    /// The assistant reads the project and replaces the screens with the
    /// ones that show the app best before capturing; off, it keeps the
    /// person's screens and only writes their steps.
    var choosesScreens: Bool {
        get { assistantChoosesScreens ?? true }
        set { assistantChoosesScreens = newValue }
    }

    /// The languages captured: all of them, or only the primary one.
    var capturedLocales: [String] {
        capturesEachLanguage ? localeCodes : [primaryLocale]
    }

    /// Everything to capture: each device, language and screen; without
    /// screenshots, only the iPhone screens the artwork shows.
    var targets: [AutopilotCaptureTarget] {
        guard makesScreenshots else { return artworkTargets }
        return displayTypes.flatMap { display in
            capturedLocales.flatMap { locale in
                screens(on: display).flatMap { screen in
                    display == .iPhoneDuo
                        ? duoTargets(screenID: screen.id, locale: locale)
                        : [AutopilotCaptureTarget(screenID: screen.id, displayType: display, locale: locale)]
                }
            }
        }
    }

    /// The screens a device captures: the set's on iPhone and iPad, its own
    /// on Apple Watch and Apple Vision Pro.
    func screens(on display: ScreenshotDisplayType) -> [AutopilotScreen] {
        guard display.hasOwnScreens else { return screens }
        return deviceScreens?.first { $0.displayType == display }?.screens ?? []
    }

    /// The screens the run captures, each counted once: the set's, and
    /// the own ones of the run's Apple Watch and Apple Vision Pro.
    var distinctScreenCount: Int {
        screens.count + displayTypes.filter(\.hasOwnScreens).reduce(0) { $0 + screens(on: $1).count }
    }

    /// Replaces a device's own screens.
    mutating func setScreens(_ screens: [AutopilotScreen], on display: ScreenshotDisplayType) {
        guard display.hasOwnScreens else {
            self.screens = screens
            return
        }
        var sets = (deviceScreens ?? []).filter { $0.displayType != display }
        sets.append(AutopilotDeviceScreens(displayType: display, screens: screens))
        let order = ScreenshotDisplayType.ownScreens
        sets.sort { (order.firstIndex(of: $0.displayType) ?? order.count) < (order.firstIndex(of: $1.displayType) ?? order.count) }
        deviceScreens = sets
    }

    /// Screenshots per language: every device's screens.
    var screensPerLanguage: Int {
        guard makesScreenshots else { return 0 }
        return displayTypes.reduce(0) { $0 + ($1 == .iPhoneDuo ? duoShots.count : screens(on: $1).count) }
    }

    /// The languages the plan adds to the App Store.
    var addedLocaleCodes: [String] {
        localeCodes.filter { newLocaleCodes?.contains($0) == true }
    }

    var includesNewLanguages: Bool { !addedLocaleCodes.isEmpty }

    /// Includes (or leaves out) the app's languages that aren't on the App
    /// Store yet.
    mutating func setIncludesNewLanguages(_ included: Bool) {
        let new = newLocaleCodes ?? []
        localeCodes.removeAll { new.contains($0) }
        if included { localeCodes += new }
    }

    /// Plans a device, or leaves it out. iPhone is always planned.
    mutating func setPlans(_ display: ScreenshotDisplayType, _ planned: Bool) {
        guard display != .iPhone else { return }
        displayTypes.removeAll { $0 == display }
        if planned { displayTypes.append(display) }
        let leftOut = (leftOutDevices ?? []).filter { $0 != display } + (planned ? [] : [display])
        leftOutDevices = leftOut.isEmpty ? nil : leftOut
        displayTypes.sort { (ScreenshotDisplayType.studio.firstIndex(of: $0) ?? 9) < (ScreenshotDisplayType.studio.firstIndex(of: $1) ?? 9) }
    }

    /// "iPhone, iPad, Apple Watch and Apple Vision Pro".
    var devicesTitle: String {
        displayTypes.map(\.shortTitle).formatted(.list(type: .and))
    }

    /// "iPhone, iPad, Apple Watch and Apple Vision Pro · 15 languages · 17
    /// screens per language"; without screenshots, what the run makes:
    /// "Header and search artwork · 15 languages".
    var scopeTitle: String {
        let languages = localeCodes.count == 1 ? String(localized: "1 language") : String(localized: "\(localeCodes.count) languages")
        guard makesScreenshots else {
            let made = extrasTitle.map { $0.prefix(1).uppercased() + $0.dropFirst() } ?? String(localized: "Nothing to make yet")
            // The App Preview's title says its languages.
            return alsoMakes.makesArtwork ? [made, languages].joined(separator: " · ") : made
        }
        // With a device's own screens, the count is per language.
        let perLanguage = displayTypes.contains(where: \.hasOwnScreens)
        let count = perLanguage ? screensPerLanguage : screens.count
        let screenCount = switch (perLanguage, count) {
        case (true, 1): String(localized: "1 screen per language")
        case (true, _): String(localized: "\(count) screens per language")
        case (false, 1): String(localized: "1 screen")
        case (false, _): String(localized: "\(count) screens")
        }
        return [devicesTitle, languages, screenCount].joined(separator: " · ")
    }

    /// Any device's screen.
    func screen(id: String) -> AutopilotScreen? {
        screens.first { $0.id == id } ?? deviceScreens?.lazy.flatMap(\.screens).first { $0.id == id }
    }

    /// The device whose screens `screenID` is one of: the first planned
    /// device for the set's screens.
    func display(of screenID: String) -> ScreenshotDisplayType? {
        if screens.contains(where: { $0.id == screenID }) { return displayTypes.first { !$0.hasOwnScreens } ?? .iPhone }
        return deviceScreens?.first { $0.screens.contains { $0.id == screenID } }?.displayType
    }

    /// The screen's slot (its position on its device), 0-based.
    func slot(of screenID: String) -> Int? {
        if let slot = screens.firstIndex(where: { $0.id == screenID }) { return slot }
        for set in deviceScreens ?? [] {
            if let slot = set.screens.firstIndex(where: { $0.id == screenID }) { return slot }
        }
        return nil
    }

    /// The screen whose pick a screen follows: an Apple Vision Pro window
    /// follows its iPhone screen; the others are their own.
    func pickScreenID(for screenID: String) -> String {
        screen(id: screenID)?.sourceScreenID.flatMap { source in screens.contains { $0.id == source } ? source : nil } ?? screenID
    }

    /// The screens picks are made for: the set's, then Apple Watch's;
    /// without screenshots, the ones the artwork shows.
    var pickedScreens: [AutopilotScreen] {
        guard makesScreenshots else { return artworkScreens }
        return screens + (displayTypes.contains(.watch) ? screens(on: .watch) : [])
    }
}
