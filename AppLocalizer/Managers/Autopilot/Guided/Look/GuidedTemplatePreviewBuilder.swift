//
//  GuidedTemplatePreviewBuilder.swift
//  AppLocalizer
//

import Foundation

/// Lays out a gallery template the way the set will be rendered, for the
/// Look step's preview: up to five screens on iPhone, iPad, iPhone Duo or
/// Mac (a MacBook, 16:10), the Apple Vision Pro windows and the bare Apple
/// Watch screens, each with the language's caption (the primary one's, or
/// a sample, when it has none yet) and capture. iPhone Duo, Mac and Apple
/// Vision Pro borrow the iPad capture until they have their own. Nothing
/// is rendered here.
struct GuidedTemplatePreviewBuilder {
    var document: ScreenshotsDocument
    var plan: AutopilotPlan
    var appID: String
    var appName: String
    var primary: StoreLocale
    var engine: ScreenshotLayoutEngine
    /// What a slot no language has a caption for shows.
    var sampleCaptions: [ScreenshotCaption]

    /// The screens a template is previewed with.
    static let slotCount = StarterPreview.slotCount

    func preview(_ starter: TemplateStarter, on device: ScreenshotDisplayType, locale: StoreLocale) -> GuidedTemplatePreview {
        let display = device
        let screens = screens(on: display)
        let template = ScreenshotTemplate.starter(starter, id: appID, title: appName, slotCount: max(document.slotCount, screens.count, 1))
        let items = screens.map { item(for: $0, template: template, display: display, locale: locale, count: screens.count) }
        return GuidedTemplatePreview(
            starter: starter, device: device, locale: locale, items: items,
            sizeTitle: GuidedTemplatePreviewDevices.sizeTitle(device, size: items.first?.pixelSize),
            note: note(device, items: items, locale: locale),
            isInRun: device == .iPhone || plan.displayTypes.contains(device)
        )
    }

    // MARK: - Screens

    /// One screen the preview shows: its slot on the device, name, and the
    /// set slot whose caption (and, borrowed, whose iPad capture) it takes.
    private struct Screen {
        var slot: Int
        var name: String
        var captionSlot: Int?
    }

    private func screens(on display: ScreenshotDisplayType) -> [Screen] {
        switch display {
        case .watch:
            let names = document.screens(on: .watch)?.map(\.name) ?? plan.screens(on: .watch).map(\.name)
            return names.prefix(Self.slotCount).enumerated().map { Screen(slot: $0, name: $1, captionSlot: nil) }
        case .visionPro:
            return visionScreens()
        default:
            return setScreens()
        }
    }

    /// The set's first five slots; five samples when it has none yet.
    private func setScreens() -> [Screen] {
        let count = min(Self.slotCount, max(document.slotCount, plan.screens.count))
        guard count > 0 else {
            return (0..<Self.slotCount).map { Screen(slot: $0, name: String(localized: "Screen \($0 + 1)"), captionSlot: $0) }
        }
        return (0..<count).map { slot in
            let name = slot < document.slotCount || !plan.screens.indices.contains(slot) ? document.slotName(slot) : plan.screens[slot].name
            return Screen(slot: slot, name: name, captionSlot: slot)
        }
    }

    /// The set's Apple Vision Pro windows, else the plan's, else the first
    /// screens it would make them from.
    private func visionScreens() -> [Screen] {
        if let screens = document.screens(on: .visionPro), !screens.isEmpty {
            return screens.prefix(Self.slotCount).enumerated().map { Screen(slot: $0, name: $1.name, captionSlot: $1.captionSlot) }
        }
        let planned = plan.screens(on: .visionPro)
        if !planned.isEmpty {
            return planned.prefix(Self.slotCount).enumerated().map { slot, screen in
                let source = plan.screens.firstIndex { $0.id == screen.sourceScreenID }
                return Screen(slot: slot, name: screen.name, captionSlot: source ?? slot)
            }
        }
        return Array(setScreens().prefix(AutopilotPlanner.visionScreenCount))
    }

    // MARK: - Items

    private func item(
        for screen: Screen, template base: ScreenshotTemplate, display: ScreenshotDisplayType, locale: StoreLocale, count: Int
    ) -> GuidedTemplatePreviewItem {
        let found = capture(for: screen, display: display, locale: locale)
        var template = base
        // Turned the way an iPhone Duo capture is, in the render key too.
        template.canvas = template.canvas.following(found?.resolved.capture.pixelSize, on: display)
        let caption = display.hasCaptions ? caption(screen.captionSlot ?? screen.slot, locale: locale) : nil
        let templateSlot = min(screen.captionSlot ?? screen.slot, max(0, template.slots.count - 1))
        // Two phones: the screen before it stands behind.
        let behind = display.hasOwnScreens || found == nil ? nil : template.behindSlot(screen.slot, templateSlot: templateSlot, count: count).flatMap {
            capture(for: Screen(slot: $0, name: "", captionSlot: $0), display: display, locale: locale)?.resolved.capture
        }
        let layout = engine.layout(
            template, slot: templateSlot, locale: locale, displayType: display, caption: caption,
            captureSize: found?.resolved.capture.pixelSize
        )
        let key = RenderKey(
            templateHash: template.contentHash, locale: locale.code, displayType: display, slot: screen.slot, caption: caption,
            captureID: found.map { [$0.resolved.capture.id, behind?.id].compactMap(\.self).joined(separator: "+") },
            store: layout.storeSignature
        )
        return GuidedTemplatePreviewItem(
            slot: screen.slot, name: screen.name,
            job: RenderJob(key: key, layout: layout, capture: found?.resolved.capture, companion: behind),
            showsPrimaryInterface: found.map { !$0.resolved.isInterfaceLocalized } ?? false,
            borrowsIPad: found?.borrowsIPad ?? false
        )
    }

    /// The device's own capture of the screen in `locale` (the primary
    /// language's when it has none); iPhone Duo, Mac and Apple Vision Pro
    /// without one take the iPad capture of the screen's slot.
    private func capture(for screen: Screen, display: ScreenshotDisplayType, locale: StoreLocale) -> (resolved: ResolvedCapture, borrowsIPad: Bool)? {
        let captures = document.captures
        if let own = captures.capture(locale: locale.code, displayType: display, slot: screen.slot, primary: primary.code) {
            return (own, false)
        }
        guard Self.borrowers.contains(display) else { return nil }
        let slot = screen.captionSlot ?? screen.slot
        return captures.capture(locale: locale.code, displayType: .iPad, slot: slot, primary: primary.code).map { ($0, true) }
    }

    /// The devices that show the iPad capture until they have their own.
    static let borrowers: [ScreenshotDisplayType] = [.iPhoneDuo, .mac, .visionPro]

    private func caption(_ slot: Int, locale: StoreLocale) -> ScreenshotCaption? {
        document.captions.caption(locale: locale.code, slot: slot)
            ?? document.captions.caption(locale: primary.code, slot: slot)
            ?? (sampleCaptions.isEmpty ? nil : sampleCaptions[slot % sampleCaptions.count])
    }

    // MARK: - Texts

    /// What's worth knowing about the preview on `device`: how the App
    /// Store uses the set there, which screens aren't the language's (or
    /// the device's) own yet, and a Reviews screen with no reviews to quote.
    func note(_ device: ScreenshotDisplayType, items: [GuidedTemplatePreviewItem], locale: StoreLocale) -> String {
        let app = appName
        var parts = [lead(device, items: items)]
        // Bruma, not on the App Store yet, picked Social Proof: its Reviews
        // screen was empty, and only the check before push said so. It
        // shows its capture now, which the person should know.
        if items.contains(where: { $0.job.layout.reviews.map { $0.isChecked && $0.own + $0.borrowed == 0 } == true }) {
            let country = Locale.current.localizedString(forRegionCode: locale.regionCode) ?? locale.regionCode
            parts.append(String(localized: """
            \(app) has no 5-star App Store reviews in \(country) yet, so the Reviews screen shows its capture instead, \
            like the others, until it has some.
            """))
        }
        if device == .iPhoneDuo, plan.duoScreens == .inner {
            parts.append(String(localized: "The cover display shows the iPhone set."))
        }
        if device != .watch {
            if !items.isEmpty, !items.contains(where: \.hasCapture) {
                parts.append(String(localized: "There are no captures yet, so the screens stay empty until Autopilot captures them."))
            } else if locale.code != primary.code, items.contains(where: \.showsPrimaryInterface) {
                let interface = items.contains(where: \.borrowsIPad) ? ScreenshotDisplayType.iPad : device
                parts.append(String(localized: """
                \(app)’s \(interface.shortTitle) interface isn’t captured in \(locale.shortName) yet, so the \(primary.shortName) interface \
                shows under the \(locale.shortName) captions (marked) until Autopilot captures it.
                """))
            }
        }
        return parts.joined(separator: " ")
    }

    /// How the App Store uses the set on `device`, and what stands in for
    /// the device's own captures.
    private func lead(_ device: ScreenshotDisplayType, items: [GuidedTemplatePreviewItem]) -> String {
        if device == .watch { return watchLead(isCaptured: items.contains { $0.hasCapture }) }
        if items.contains(where: \.borrowsIPad), let borrowed = borrowedLead(device) { return borrowed }
        return ownLead(device)
    }

    private func ownLead(_ device: ScreenshotDisplayType) -> String {
        let app = appName
        switch device {
        case .iPhone:
            return String(localized: "The App Store scales this set down for smaller iPhones, so one size covers them all.")
        case .iPad:
            return String(localized: "The same template, laid out for iPad with \(app)’s iPad screens.")
        case .iPhoneDuo:
            return String(localized: "The inner display, with \(app)’s iPhone Duo captures.")
        case .mac:
            return String(localized: "Mac App Store screenshots, 16:10: \(app)’s Mac app on a MacBook, with its menu bar and window, in the template’s layout.")
        case .visionPro:
            return String(localized: "The template’s colors and type, with \(app)’s window in space.")
        default:
            return ""
        }
    }

    /// iPhone Duo, Mac and Apple Vision Pro showing the iPad captures.
    private func borrowedLead(_ device: ScreenshotDisplayType) -> String? {
        let app = appName
        switch device {
        case .iPhoneDuo:
            return String(localized: "The inner display runs \(app)’s iPad layout, so the preview uses its iPad screens until Autopilot captures iPhone Duo.")
        case .mac:
            return ownLead(.mac) + " " + String(localized: "Its iPad screens stand in until Autopilot captures the Mac app.")
        case .visionPro:
            return String(localized: """
            The template’s colors and type, with \(app)’s window in space; its iPad screens stand in until Autopilot captures \
            the windows.
            """)
        default:
            return nil
        }
    }

    private func watchLead(isCaptured: Bool) -> String {
        if isCaptured {
            return String(localized: """
            Apple shows watch screenshots as the bare screen inside its own frame, so no template is applied: this is what \
            people will see, whichever template you pick.
            """)
        }
        return String(localized: """
        Apple shows watch screenshots as the bare screen inside its own frame, so no template is applied. \(appName)’s watch \
        screens show here once Autopilot captures them.
        """)
    }
}
