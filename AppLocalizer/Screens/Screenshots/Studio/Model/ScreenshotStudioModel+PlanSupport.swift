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
            parts.append(String(localized: "inner display"))
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
