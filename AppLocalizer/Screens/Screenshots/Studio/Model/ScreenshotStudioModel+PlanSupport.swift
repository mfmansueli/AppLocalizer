//
//  ScreenshotStudioModel+PlanSupport.swift
//  AppLocalizer
//

import Foundation

/// What the Plan step says about the devices and languages the app
/// supports: where AppLocalizer found them, why each device is required,
/// and the app's languages the App Store page doesn't have yet.
extension ScreenshotStudioModel {
    /// "Found in Lumen 1.4 on App Store Connect and in the Xcode project:
    /// targets … and 15 languages in Localizable.xcstrings, 12 of them on
    /// the App Store." Before the assistant reports the project, what App
    /// Store Connect says alone; nil when it says nothing.
    var planFoundText: String? {
        let version = "\(app.name) \(screenshots.context.version.versionString)"
        guard let profile = appSupport?.profile(for: app.id) else {
            guard let found = appStoreConnectFound else { return nil }
            return String(localized: "Found in \(version) on App Store Connect: \(found).")
        }
        let found = profile.foundSummary(storeLocales: locales.map(\.code))
        guard !found.isEmpty else { return nil }
        return String(localized: "Found in \(version) on App Store Connect and in the Xcode project: \(found).")
    }

    /// What the plan makes: "Autopilot captures iPhone, iPhone Duo, iPad,
    /// and Apple Watch in 8 languages." and where iPhone Duo stands.
    func planCaptureText(_ plan: AutopilotPlan) -> String {
        let devices = plan.devicesTitle
        let count = plan.localeCodes.count
        var text = plan.capturesEachLanguage
            ? (count == 1
                ? String(localized: "Autopilot captures \(devices) in 1 language.")
                : String(localized: "Autopilot captures \(devices) in \(count) languages."))
            : String(localized: "Autopilot captures \(devices) in \(primaryLocale.shortName), and uses those captures under every language’s captions.")
        text += " " + (plan.displayTypes.contains(.iPhoneDuo)
            ? String(localized: "iPhone Duo is in every plan: Apple requires its screenshots from April 2027.")
            : String(localized: "iPhone Duo is off, so its screenshots are left to upload by hand: Apple requires them from April 2027."))
        return text
    }

    /// "It tries every screen in English and Japanese first, so what breaks
    /// in other languages shows up once." Nil with one language captured.
    func planRehearsalText(_ plan: AutopilotPlan) -> String? {
        guard let locale = plan.rehearsalLocale else { return nil }
        let primary = StoreLocaleCatalog.locale(code: plan.primaryLocale)?.shortName ?? plan.primaryLocale
        let other = StoreLocaleCatalog.locale(code: locale)?.shortName ?? locale
        return String(localized: "It tries every screen in \(primary) and \(other) first, so what breaks in other languages shows up once, not in each.")
    }

    /// "its build has an Apple Watch app, and it has a visionOS version".
    private var appStoreConnectFound: String? {
        let context = screenshots.context
        let parts = [
            context.hasWatchApp ? String(localized: "its build has an Apple Watch app") : nil,
            context.hasVisionVersion ? String(localized: "it has a visionOS version") : nil,
        ].compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: String(localized: ", and "))
    }

    /// iPhone, iPhone Duo and iPad, then Apple Watch and Apple Vision Pro
    /// when the app runs there or the plan has them.
    func planDevices(_ plan: AutopilotPlan) -> [ScreenshotDisplayType] {
        ScreenshotDisplayType.studio.filter { $0.isRendered || devices.contains($0) || plan.displayTypes.contains($0) }
    }

    /// Why the App Store wants this device's screenshots, if it does:
    /// "Lumen runs on iPad", "1.4 adds visionOS". iPhone Duo is Apple's
    /// rule from April 2027, so it's required already.
    func requiredReason(_ display: ScreenshotDisplayType) -> String? {
        if display == .iPhone { return String(localized: "for every iPhone app") }
        if display == .iPhoneDuo { return String(localized: "from April 2027 for apps built with the iOS 27.1 SDK") }
        if let reason = appSupport?.profile(for: app.id)?.device(display)?.reason { return reason }
        let version = screenshots.context.version.versionString
        if display == .visionPro, screenshots.context.hasVisionVersion {
            return String(localized: "\(version) has a visionOS version")
        }
        if display == .watch, screenshots.context.hasWatchApp {
            return String(localized: "the \(version) build has an Apple Watch app")
        }
        return nil
    }

    /// "2752 × 2064 · required: Lumen runs on iPad", iPhone Duo's inner
    /// display and when Apple's rule starts, and when it's off and
    /// required, that its screenshots have to be uploaded by hand.
    func planDeviceDetail(_ display: ScreenshotDisplayType, plan: AutopilotPlan) -> String {
        // Autopilot captures iPad on its side.
        var parts = [display == .iPad ? display.portraitPixelSize.rotated.title : display.defaultPixelSize.title]
        switch display {
        case .iPad where requiredReason(.iPad) == nil:
            parts.append(String(localized: "landscape"))
        case .iPhoneDuo:
            parts.append(Self.duoShowsTitle(plan))
        case .watch:
            parts.append(String(localized: "Ultra 3"))
        default:
            break
        }
        if let reason = requiredReason(display) {
            let isRule = display == .iPhone || display == .iPhoneDuo
            parts.append(isRule ? String(localized: "required \(reason)") : String(localized: "required: \(reason)"))
        }
        var detail = parts.joined(separator: " · ")
        if display != .iPhone, !plan.displayTypes.contains(display), requiredReason(display) != nil {
            detail += ". " + String(localized: "You’ll need to upload these by hand before submitting.")
        }
        return detail
    }

    /// Under "What this run makes"'s rows: each required device left out,
    /// whose screenshots are uploaded by hand.
    func planDeviceNotes(_ plan: AutopilotPlan) -> [String] {
        guard plan.makesScreenshots else { return [] }
        var notes: [String] = []
        for display in planDevices(plan) where display != .iPhone && !plan.displayTypes.contains(display) {
            guard let reason = requiredReason(display) else { continue }
            let required = display == .iPhoneDuo ? String(localized: "required \(reason)") : String(localized: "required: \(reason)")
            notes.append(String(localized: "\(display.title) is left out (\(required)). You’ll need to upload these by hand before submitting."))
        }
        return notes
    }

    /// "inner display", "cover display", "both displays side by side",
    /// "inner and cover, separately".
    static func duoShowsTitle(_ plan: AutopilotPlan) -> String {
        switch (plan.duoScreens, plan.duoBoth) {
        case (.inner, _): String(localized: "inner display")
        case (.cover, _): String(localized: "cover display")
        case (.both, .sideBySide): String(localized: "both displays side by side")
        case (.both, .separate): String(localized: "inner and cover, separately")
        }
    }

    /// The iPhone Duo row's note: what each choice shows and costs.
    static func duoNote(_ plan: AutopilotPlan) -> String {
        let size = AutopilotDuoPose.open.portraitPixelSize.title
        let count = plan.duoShots.count
        switch (plan.duoScreens, plan.duoBoth) {
        case (.inner, _):
            return String(localized: "Unfolded, as Apple requires: the inner display at \(size). AppLocalizer opens the Duo in Device Hub for each capture.")
        case (.cover, _):
            return String(localized: "Folded: the app on the cover display, placed on the \(size) canvas. Faster, since the Duo never opens, but people don’t see the big screen.")
        case (.both, .separate):
            guard plan.screens.count * 2 > AutopilotPlan.duoShotLimit else {
                return String(localized: "Each screen unfolded, then folded: \(count) screenshots per language.")
            }
            return String(localized: "Each screen unfolded, then folded: \(count) screenshots per language. Apple allows 10, so only the first \(plan.duoSeparateCovers) screens get a folded one.")
        case (.both, .sideBySide):
            return String(localized: "Each screenshot shows the Duo unfolded with the folded cover beside it: \(count) per language, both states in one image.")
        }
    }

    /// Plans a device or leaves it out; Apple Vision Pro starts with the
    /// first iPhone screens.
    func setPlans(_ display: ScreenshotDisplayType, _ planned: Bool) {
        updatePlan { plan in
            plan.setPlans(display, planned)
            if planned, display == .visionPro, plan.screens(on: .visionPro).isEmpty {
                plan.setScreens(AutopilotPlanner.visionScreens(from: plan.screens), on: .visionPro)
            }
        }
    }

    /// "All 12 languages on the App Store".
    func storeLanguagesTitle(_ plan: AutopilotPlan) -> String {
        let count = plan.localeCodes.count - plan.addedLocaleCodes.count
        return count == 1
            ? String(localized: "The App Store’s language")
            : String(localized: "All \(count) languages on the App Store")
    }

    /// "3 more the app supports: Polish, Turkish, Hebrew"; nil when the
    /// project has none the App Store page lacks.
    func newLanguagesTitle(_ plan: AutopilotPlan) -> String? {
        let codes = plan.newLocaleCodes ?? []
        guard !codes.isEmpty else { return nil }
        let names = codes.map { StoreLocaleCatalog.locale(code: $0)?.shortName ?? $0 }.formatted(.list(type: .and))
        return codes.count == 1
            ? String(localized: "1 more the app supports: \(names)")
            : String(localized: "\(codes.count) more the app supports: \(names)")
    }

    /// "In Localizable.xcstrings but not on the App Store yet. …"
    var newLanguagesDetail: String {
        let source = appSupport?.profile(for: app.id)?.languageSource ?? String(localized: "the project")
        return String(localized: "In \(source) but not on the App Store yet. Store Page suggests creating their pages; they’re created when you push.")
    }

    func setIncludesNewLanguages(_ included: Bool) {
        updatePlan { $0.setIncludesNewLanguages(included) }
    }
}
