//
//  AutopilotPlanner.swift
//  AppLocalizer
//

import Foundation

/// The plan Run Autopilot… opens with: the last run's when there is one,
/// else the screens the app's captures and captions name, every language
/// of the version plus the ones the app supports that aren't on the App
/// Store yet, iPhone, iPhone Duo (Apple's rule from April 2027) and every
/// other device the app runs on.
enum AutopilotPlanner {
    /// Apple Vision Pro windows a new plan starts with, from the first
    /// iPhone screens.
    static let visionScreenCount = 3

    static func plan(
        document: ScreenshotsDocument?,
        live: LiveScreenshots,
        primaryLocale: StoreLocale,
        localeCodes: [String],
        previous: AutopilotRun?,
        support: AutopilotSupport = .none
    ) -> AutopilotPlan {
        let primary = primaryLocale.code
        var locales = [primary] + localeCodes.filter { $0 != primary && !support.newLocaleCodes.contains($0) }
        if locales.count == 1, let document { locales += document.scope.orderedLocales(in: StoreLocaleCatalog.all.map(\.code)).filter { $0 != primary } }
        let new = support.newLocaleCodes.filter { !locales.contains($0) }

        guard var plan = previous?.plan else {
            let screens = screens(from: document, primary: primary)
            var plan = AutopilotPlan(
                screens: screens,
                displayTypes: devices(document: document, live: live, support: support),
                localeCodes: locales,
                primaryLocale: primary
            )
            plan.newLocaleCodes = new
            plan.setIncludesNewLanguages(true)
            if plan.displayTypes.contains(.visionPro) { plan.setScreens(visionScreens(from: screens), on: .visionPro) }
            return plan
        }
        let includedNew = previous?.plan.newLocaleCodes == nil || plan.includesNewLanguages
        // A device the app gained since the last run joins, unless the
        // person turned it off.
        plan = applyingRules(to: plan)
        let leftOut = plan.leftOutDevices ?? []
        for display in ScreenshotDisplayType.ownScreens
            where support.devices.contains(display) && !plan.displayTypes.contains(display) && !leftOut.contains(display)
        {
            plan.setPlans(display, true)
        }
        if plan.displayTypes.contains(.visionPro), plan.screens(on: .visionPro).isEmpty {
            plan.setScreens(visionScreens(from: plan.screens), on: .visionPro)
        }
        plan.localeCodes = locales
        plan.newLocaleCodes = new
        plan.setIncludesNewLanguages(includedNew)
        plan.primaryLocale = primary
        return plan
    }

    /// The rules every plan follows, made before them or not: iPhone Duo,
    /// unless the person turned it off.
    static func applyingRules(to plan: AutopilotPlan) -> AutopilotPlan {
        var plan = plan
        if !plan.displayTypes.contains(.iPhoneDuo), plan.leftOutDevices?.contains(.iPhoneDuo) != true {
            plan.setPlans(.iPhoneDuo, true)
        }
        return plan
    }

    /// iPhone and iPhone Duo (every iPhone app needs its screenshots from
    /// April 2027), then iPad, Apple Watch and Apple Vision Pro when the
    /// app runs there.
    static func devices(document: ScreenshotsDocument?, live: LiveScreenshots, support: AutopilotSupport) -> [ScreenshotDisplayType] {
        ScreenshotDisplayType.studio.filter { display in
            switch display {
            case .iPhone, .iPhoneDuo: true
            case .iPad: support.devices.contains(.iPad) || hasIPad(document: document, live: live)
            default: support.devices.contains(display)
            }
        }
    }

    /// Apple Vision Pro's windows: the same moments as the first iPhone
    /// screens, with their captions.
    static func visionScreens(from screens: [AutopilotScreen]) -> [AutopilotScreen] {
        screens.prefix(visionScreenCount).map { screen in
            AutopilotScreen(id: "vision-\(screen.id)", name: screen.name, caption: screen.caption, sourceScreenID: screen.id)
        }
    }

    /// The slots the document names, with the primary language's captions.
    static func screens(from document: ScreenshotsDocument?, primary: String) -> [AutopilotScreen] {
        guard let document, !document.captures.isEmpty || !document.slotNames.isEmpty else { return [] }
        return (0..<document.slotCount).map { slot in
            let name = document.slotName(slot)
            let caption = document.captions.caption(locale: primary, slot: slot)?.headline ?? ""
            return AutopilotScreen(id: AutopilotScreen.identifier(for: name) + "-\(slot + 1)", name: name, caption: caption)
        }
    }

    /// The app shows iPad screenshots or has iPad captures. With nothing to
    /// go by, iPad is planned too; the person can turn it off.
    static func hasIPad(document: ScreenshotsDocument?, live: LiveScreenshots) -> Bool {
        let hasAnything = !(document?.captures.isEmpty ?? true) || !live.screenshotSets.isEmpty
        guard hasAnything else { return true }
        return live.screenshotSets.contains { $0.displayType == .iPad && !$0.screenshots.isEmpty }
            || document?.captures.captures.contains { $0.displayType == .iPad } == true
    }
}
