//
//  AutopilotLocalizer.swift
//  AppLocalizer
//

import Foundation

/// Localize and check: turns the chosen direction and the picks into the
/// app's screenshot document (template version, captures, slot names,
/// scope), checks every language's captions with it, and saves the
/// captions the assistant writes.
@MainActor
struct AutopilotLocalizer {
    let context: AutopilotContext
    let now: Date

    /// Saves the direction as the next template version with the run's
    /// captures; returns the version number.
    func apply(_ direction: AutopilotDirection, of run: AutopilotRun) async throws -> Int {
        let services = context.services
        let primary = context.primaryLocale.code
        var document = try await services.loadDocument(for: context.app, primaryLocale: context.primaryLocale)

        var template = direction.template
        template.id = document.template?.id ?? context.app.id
        template.name = "\(context.app.name) · \(direction.name)"
        template.slots = Self.slots(template.slots, count: run.plan.screens.count)
        template.canvas = Self.canvas(template.canvas, matching: run)
        let author: ChangeSource = direction.client.map { .assistant(client: $0) } ?? .you
        let note = String(localized: "Autopilot · \(direction.name)")
        if var history = document.history {
            _ = history.save(template, date: now, author: author, note: note)
            document.history = history
        } else {
            document.history = .starting(with: template, date: now, author: author, note: note)
        }

        Self.place(run, in: &document)
        for (slot, screen) in run.plan.screens.enumerated() {
            let caption = screen.caption.trimmingCharacters(in: .whitespacesAndNewlines)
            let current = document.captions.caption(locale: primary, slot: slot)
            guard !caption.isEmpty, current?.headline != caption else { continue }
            document.captions.setCaption(ScreenshotCaption(headline: caption, subhead: current?.subhead, provenance: .written), locale: primary, slot: slot)
        }
        document.scope.setLocalized(run.plan.localeCodes)
        try await services.saveDocument(document, for: context.app)
        return document.history?.currentNumber ?? 1
    }

    /// Puts the run's final captures on the document's slots, with the slot
    /// names and each device's own screens: iPhone Duo's captures go where
    /// the plan's Duo row says (`duoPlacement`).
    nonisolated static func place(_ run: AutopilotRun, in document: inout ScreenshotsDocument) {
        // The Duo's cover display beside the inner one only when the plan
        // still says side by side.
        document.captures.removeCompanions(on: .iPhoneDuo)
        for target in run.plan.targets {
            guard let capture = run.finalCapture(for: target), var slot = run.plan.slot(of: target.screenID),
                  let screen = run.plan.screen(id: target.screenID) else { continue }
            var isCompanion: Bool?
            if let pose = run.plan.duoPose(for: target) {
                guard let placed = run.plan.duoPlacement(slot: slot, pose: pose) else { continue }
                slot = placed.slot
                isCompanion = placed.isCompanion ? true : nil
            }
            let suffix = isCompanion == true ? "_cover" : ""
            let fileName = String(format: "%@/%@-%02d_%@%@.png", target.locale, target.displayType.deviceName, slot + 1, screen.name, suffix)
            document.captures.add(ScreenshotCapture(
                id: capture.captureID, locale: target.locale, displayType: target.displayType, slot: slot,
                source: .autopilot, fileName: fileName, pixelSize: capture.pixelSize, importedAt: capture.receivedAt, isCompanion: isCompanion
            ))
        }
        document.slotNames = run.plan.screens.map(\.name)
        for display in ScreenshotDisplayType.ownScreens {
            let screens = run.plan.displayTypes.contains(display) ? run.plan.screens(on: display) : []
            document.setScreens(screens.map { screen in
                DeviceScreen(name: screen.name, captionSlot: display.hasCaptions ? screen.sourceScreenID.flatMap { run.plan.slot(of: $0) } : nil)
            }, on: display)
        }
        document.setScreens(run.plan.duoDeviceScreens, on: .iPhoneDuo)
    }

    /// The canvas turned the way each device's captures are: the device
    /// lies the canvas's way, so a landscape capture on a portrait canvas
    /// would be cropped by half and fail its size check (iPhone Duo's
    /// unfolded display, an iPad held sideways). The way most of a device's
    /// captures are wins; a device without captures keeps the direction's.
    /// iPhone Duo's closed screenshots frame the folded phone inside the
    /// set's canvas, so only its open captures count.
    static func canvas(_ canvas: TemplateCanvas, matching run: AutopilotRun) -> TemplateCanvas {
        var canvas = canvas
        for display in run.plan.displayTypes where display.isRendered {
            let sizes = run.plan.targets.filter { $0.displayType == display }.compactMap { run.finalCapture(for: $0)?.pixelSize }
                .filter { display != .iPhoneDuo || !CaptureSizeRules.isDuoOuterDisplay($0) }
            guard !sizes.isEmpty else { continue }
            let landscape = sizes.count(where: \.isLandscape)
            canvas.setOrientation(landscape * 2 > sizes.count ? .landscape : .portrait, for: display)
        }
        return canvas
    }

    /// The document as saved now.
    func document() async -> ScreenshotsDocument? {
        try? await context.services.loadDocument(for: context.app, primaryLocale: context.primaryLocale)
    }

    /// Lays out every caption of `locale` with the current template on each
    /// device: the ones that don't fit (or are missing) go to the
    /// assistant.
    func check(locale code: String, of run: AutopilotRun, in document: ScreenshotsDocument) -> AutopilotLocaleCheck {
        guard let template = document.template else { return AutopilotLocaleCheck(status: .fits(note: nil), overflows: []) }
        return AutopilotCaptionChecker(
            template: template, captions: document.captions, displayTypes: run.plan.displayTypes.filter(\.isRendered), slotCount: run.plan.screens.count,
            primaryLocale: context.primaryLocale.code, catalog: context.services.fonts, duoClosedSlots: run.plan.duoCoverSlots
        ).check(locale: code)
    }

    /// The language checks on a direction, with the captions saved now and
    /// the plan's for the primary language.
    func directionChecks(for template: ScreenshotTemplate, of run: AutopilotRun) async -> [AutopilotDirectionCheck] {
        var captions = await document()?.captions ?? CaptionBook()
        let primary = run.plan.primaryLocale
        for (slot, screen) in run.plan.screens.enumerated() where captions.caption(locale: primary, slot: slot) == nil && !screen.caption.isEmpty {
            captions.setCaption(ScreenshotCaption(headline: screen.caption, subhead: nil, provenance: .written), locale: run.plan.primaryLocale, slot: slot)
        }
        var template = template
        template.slots = Self.slots(template.slots, count: run.plan.screens.count)
        return AutopilotCaptionChecker(
            template: template, captions: captions, displayTypes: run.plan.displayTypes.filter(\.isRendered), slotCount: run.plan.screens.count,
            primaryLocale: run.plan.primaryLocale, catalog: context.services.fonts, duoClosedSlots: run.plan.duoCoverSlots
        ).directionChecks(locales: run.plan.localeCodes)
    }

    /// Saves captions the assistant wrote; returns the ones that replaced a
    /// caption that didn't fit.
    func save(_ captions: [AutopilotCaptionUpdate], client: String, overflows: [AutopilotOverflow]) async throws -> [AutopilotShortening] {
        var document = try await context.services.loadDocument(for: context.app, primaryLocale: context.primaryLocale)
        var shortened: [AutopilotShortening] = []
        for item in captions {
            let current = document.captions.caption(locale: item.locale, slot: item.slot)
            let caption = ScreenshotCaption(
                headline: item.headline, subhead: item.subhead ?? current?.subhead, provenance: .assistant(client: client, date: now)
            )
            document.captions.setCaption(caption, locale: item.locale, slot: item.slot)
            let wasTooLong = overflows.contains { $0.locale == item.locale && $0.slot == item.slot && !$0.headline.isEmpty }
            if wasTooLong, let before = current?.headline, before != item.headline {
                shortened.append(AutopilotShortening(locale: item.locale, slot: item.slot, before: before, after: item.headline, client: client))
            }
        }
        try await context.services.saveDocument(document, for: context.app)
        return shortened
    }

    /// `count` slots: the template's own first, then standard ones; the
    /// first is the hero.
    static func slots(_ slots: [TemplateSlot], count: Int) -> [TemplateSlot] {
        let count = min(max(count, 1), ScreenshotTemplate.maximumSlots)
        var result = Array(slots.prefix(count))
        while result.count < count {
            result.append(TemplateSlot(layout: result.isEmpty ? .hero : .standard))
        }
        return result
    }
}
