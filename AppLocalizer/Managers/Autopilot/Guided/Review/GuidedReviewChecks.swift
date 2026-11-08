//
//  GuidedReviewChecks.swift
//  AppLocalizer
//

import Foundation

/// The checks beside each part in Review & push, from what the run
/// recorded: every device, every screenshot in its own language (and the
/// gap the run filled), the languages checked, the captions shortened
/// (each language's to confirm), right-to-left, the captures' text, the
/// artwork's languages and loop, the App Preview's length, music and
/// languages.
enum GuidedReviewChecks {
    /// - Parameter app: "Lumen", for the screenshots' interface check.
    static func checks(
        for part: GuidedReviewPart, run: AutopilotRun, previews: [ExtrasPreviewFile] = [], app: String? = nil
    ) -> [GuidedCheck] {
        switch part {
        case .screenshots: screenshots(run, app: app)
        case .artwork: artwork(run)
        case .appPreview: appPreview(run, previews: previews)
        }
    }

    /// Checks still waiting on the person: shortenings not confirmed yet.
    static func toConfirm(in run: AutopilotRun) -> [GuidedCheck] {
        screenshots(run, app: nil).filter { $0.state == .toConfirm }
    }

    // MARK: - Screenshots

    private static func screenshots(_ run: AutopilotRun, app: String?) -> [GuidedCheck] {
        let plan = run.plan
        let total = plan.localeCodes.count
        let checked = plan.localeCodes.count { run.localeStatus[$0]?.isDone == true }
        var checks = [deviceCheck(run, allChecked: checked == total), interfaceCheck(run, app: app)]
        let shortened = Set(run.shortenings.map(\.locale))
        let fitAsWritten = plan.localeCodes.count { run.localeStatus[$0]?.isDone == true && !shortened.contains($0) }
        if checked == total {
            checks.append(GuidedCheck(
                id: "fits", text: fitAsWritten == 1
                    ? String(localized: "Every caption fits in 1 language as written")
                    : String(localized: "Every caption fits in \(fitAsWritten) languages as written"),
                state: .passed
            ))
        } else {
            checks.append(GuidedCheck(id: "fits", text: String(localized: "\(checked) of \(total) languages checked"), state: .attention))
        }
        for locale in plan.localeCodes where shortened.contains(locale) {
            let shortenings = run.shortenings.filter { $0.locale == locale }
            let name = StoreLocaleCatalog.locale(code: locale)?.shortName ?? locale
            let client = shortenings.first?.client ?? run.client ?? String(localized: "the assistant")
            let text = shortenings.count == 1
                ? String(localized: "\(name): 1 caption was shortened by \(client)")
                : String(localized: "\(name): \(shortenings.count) captions were shortened by \(client)")
            let confirmed = shortenings.allSatisfy { run.guidedReview?.isConfirmed($0) == true }
            checks.append(GuidedCheck(id: "short-\(locale)", text: text, state: confirmed ? .passed : .toConfirm, shortenings: shortenings))
        }
        let rightToLeft = plan.localeCodes.compactMap(StoreLocaleCatalog.locale(code:)).filter(\.isRTL)
        if !rightToLeft.isEmpty {
            let names = rightToLeft.map(\.shortName).formatted(.list(type: .and))
            let text = rightToLeft.count == 1
                ? String(localized: "\(names) mirrors right to left")
                : String(localized: "\(names) mirror right to left")
            checks.append(GuidedCheck(id: "rtl", text: text, state: .passed))
        }
        checks.append(captureCheck(run))
        return checks
    }

    /// "Every device in the run: iPhone and iPad, each checked in every
    /// language".
    private static func deviceCheck(_ run: AutopilotRun, allChecked: Bool) -> GuidedCheck {
        let plan = run.plan
        // In the App Store's order, as the device switch has them.
        let devices = GuidedTemplatePreviewDevices.order.filter(plan.displayTypes.contains)
            .map(GuidedTemplatePreviewDevices.title).formatted(.list(type: .and))
        let text = allChecked && plan.displayTypes.count > 1 && plan.localeCodes.count > 1
            ? String(localized: "Every device in the run: \(devices), each checked in every language")
            : String(localized: "Every device in the run: \(devices)")
        return GuidedCheck(id: "devices", text: text, state: allChecked ? .passed : .attention)
    }

    /// Every screenshot shows the app's own interface in its language:
    /// each device has a capture of every screen in every language, and
    /// where iPad, iPhone Duo or Mac had only some before the run, it says
    /// so ("iPad captured in all 18 (before, iPad screens existed in 4)").
    /// Captured in one language is the person's choice, not a problem.
    private static func interfaceCheck(_ run: AutopilotRun, app: String?) -> GuidedCheck {
        let plan = run.plan
        let app = app ?? String(localized: "the app")
        let primary = StoreLocaleCatalog.locale(code: plan.primaryLocale)?.shortName ?? plan.primaryLocale
        guard plan.capturesEachLanguage || plan.localeCodes.count == 1 else {
            return GuidedCheck(
                id: "interface", text: String(localized: "Captured in \(primary) only, as planned: every language shows \(app)’s \(primary) interface"),
                state: .passed
            )
        }
        let missing = plan.displayTypes.compactMap { display -> String? in
            let locales = Set(plan.targets.filter { $0.displayType == display && run.finalCapture(for: $0) == nil }.map(\.locale))
            guard !locales.isEmpty else { return nil }
            return locales.count == 1
                ? String(localized: "\(display.shortTitle) in 1 language")
                : String(localized: "\(display.shortTitle) in \(locales.count) languages")
        }
        if !missing.isEmpty {
            return GuidedCheck(
                id: "interface",
                text: String(localized: "Not captured: \(missing.formatted(.list(type: .and))); those screenshots show the \(primary) interface"),
                state: .attention
            )
        }
        let gaps = (run.interfaceGaps ?? []).filter { plan.displayTypes.contains($0.displayType) }
        guard !gaps.isEmpty else {
            return GuidedCheck(id: "interface", text: String(localized: "Every screenshot shows \(app) in its own language"), state: .passed)
        }
        let devices = gaps.map(\.displayType.shortTitle).formatted(.list(type: .and))
        let before = AutopilotInterfaceGap.existed(gaps)
        return GuidedCheck(
            id: "interface",
            text: String(localized: "Every screenshot shows \(app) in its own language: \(devices) captured in all \(plan.localeCodes.count) (\(before))"),
            state: .passed
        )
    }

    /// The final captures: in the right language, nothing cut off, no
    /// system prompt, not mostly blank; and which problems were captured
    /// again or kept as they were (MB Admin's said "2 problems were fixed
    /// and captured again" when one was kept).
    private static func captureCheck(_ run: AutopilotRun) -> GuidedCheck {
        let flagged = run.plan.targets.compactMap(run.finalCapture(for:)).filter { !run.textIssues(of: $0).isEmpty }
        if !flagged.isEmpty {
            // Each one said: Bruma's run said "22 captures to look at: open
            // Pick or the captures to see what" with no Pick in its steps.
            return GuidedCheck(
                id: "captures", text: flagged.count == 1
                    ? String(localized: "1 capture to look at: click its screen to see it larger")
                    : String(localized: "\(flagged.count) captures to look at: click a screen to see it larger"),
                state: .attention, details: details(of: flagged, in: run)
            )
        }
        let recaptured = run.problems.count { $0.resolution == .captured }
        let kept = run.problems.count { $0.resolution == .keptCapture }
        var notes: [String] = []
        if recaptured > 0 {
            notes.append(recaptured == 1
                ? String(localized: "1 problem was fixed and captured again")
                : String(localized: "\(recaptured) problems were fixed and captured again"))
        }
        if kept > 0 {
            notes.append(kept == 1 ? String(localized: "1 capture was kept as it was") : String(localized: "\(kept) captures were kept as they were"))
        }
        let text = notes.isEmpty
            ? String(localized: "No alert, prompt, cut-off text or blank screen in any capture")
            : String(localized: "No alert, prompt, cut-off text or blank screen") + " · " + notes.joined(separator: ", ")
        return GuidedCheck(id: "captures", text: text, state: .passed)
    }

    /// The most lines a check to look at lists.
    static let detailLines = 6

    /// "German · iPad · Chat: Cut-off text: “Garten ver…”.", in the plan's
    /// order, then "and 16 more".
    private static func details(of captures: [AutopilotCapture], in run: AutopilotRun) -> [String] {
        let lines = captures.map { capture in
            let target = capture.target
            let language = StoreLocaleCatalog.locale(code: target.locale)?.shortName ?? target.locale
            let screen = run.plan.screens(on: target.displayType).first { $0.id == target.screenID }?.name ?? target.screenID
            let found = run.textIssues(of: capture).map(\.message).joined(separator: " ")
            return "\(language) · \(target.displayType.shortTitle) · \(screen): \(found)"
        }
        return limited(lines)
    }

    /// `lines`, at most `detailLines` of them, then "and 16 more".
    private static func limited(_ lines: [String]) -> [String] {
        guard lines.count > detailLines else { return lines }
        return Array(lines.prefix(detailLines)) + [String(localized: "and \(lines.count - detailLines) more")]
    }

    // MARK: - Header and search

    private static func artwork(_ run: AutopilotRun) -> [GuidedCheck] {
        let plan = run.plan
        let progress = run.extrasProgress
        // Nothing to check until it's made: Bruma's run showed its count as
        // a red "!" and earlier passes beside it for the hour of a remake.
        if run.loopReview?.isRemaking == true {
            let total = plan.localeCodes.count
            let done = min(progress?.artworkDone ?? 0, total)
            return [GuidedCheck(
                id: "made",
                text: String(localized: "Making the new loop in \(done) of \(total) languages. Its checks run as each is made."),
                state: .working
            )]
        }
        var checks: [GuidedCheck] = []
        if let problem = progress?.artworkProblem {
            checks.append(GuidedCheck(id: "made", text: problem, state: .attention))
        } else {
            let total = plan.localeCodes.count
            let done = min(progress?.artworkDone ?? 0, total)
            checks.append(GuidedCheck(
                id: "made",
                text: done >= total
                    ? (total == 1 ? String(localized: "Made in 1 language") : String(localized: "Made in every language: \(total)"))
                    : String(localized: "Made in \(done) of \(total) languages"),
                state: done >= total ? .passed : .attention
            ))
        }
        let tooLong = progress?.artworkTooLong ?? []
        checks.append(tooLong.isEmpty
            ? GuidedCheck(id: "texts", text: String(localized: "The name and phrases fit in every language"), state: .passed)
            : GuidedCheck(
                id: "texts",
                text: String(localized: "Too long to fit: \(tooLong.map { StoreLocaleCatalog.locale(code: $0)?.shortName ?? $0 }.formatted(.list(type: .and)))"),
                state: .attention
            ))
        if let found = findingsCheck(progress?.artworkChecks ?? []) { checks.append(found) }
        if plan.alsoMakes.makesMotion {
            let approved = run.loopReview?.approvedAt != nil
            checks.append(GuidedCheck(
                id: "loop",
                text: approved
                    ? String(localized: "\(AutopilotArtworkMotion.loopSeconds)-second loop · approved · plays muted on repeat")
                    : String(localized: "\(AutopilotArtworkMotion.loopSeconds)-second loop · plays muted on repeat"),
                state: .passed
            ))
        } else {
            checks.append(GuidedCheck(id: "still", text: String(localized: "Still images, one per language"), state: .passed))
        }
        return checks
    }

    /// What the artwork's checks found, each said: Bruma's log said
    /// "Artwork checks: 24 warnings, nothing that blocks the push" while
    /// Review showed every check passed.
    private static func findingsCheck(_ found: [ArtworkCheck]) -> GuidedCheck? {
        guard !found.isEmpty else { return nil }
        let errors = found.count(where: \.isError)
        let warnings = found.count - errors
        let text = switch (errors, warnings) {
        case (1, _): String(localized: "1 error keeps that image out of the push")
        case (2..., _): String(localized: "\(errors) errors keep those images out of the push")
        case (_, 1): String(localized: "1 warning to look at; it doesn’t keep anything out of the push")
        default: String(localized: "\(warnings) warnings to look at; none keeps anything out of the push")
        }
        // Errors first, as the checks come.
        return GuidedCheck(id: "findings", text: text, state: .attention, details: limited(found.map(\.text)))
    }

    // MARK: - App Preview

    /// "Music: Soft ambient · picked for this app".
    private static func musicText(_ plan: AutopilotPlan) -> String {
        let music = plan.alsoMakes.previewMusic
        if music.track == .ownFile { return String(localized: "Music: \(music.title) · you confirmed the rights") }
        if plan.alsoMakes.music == nil, plan.alsoMakes.suggestedMusic != nil { return String(localized: "Music: \(music.title) · picked for this app") }
        return String(localized: "Music: \(music.title) · from AppLocalizer’s library")
    }

    private static func appPreview(_ run: AutopilotRun, previews: [ExtrasPreviewFile]) -> [GuidedCheck] {
        let plan = run.plan
        var checks: [GuidedCheck] = []
        if let file = previews.first(where: { $0.locale == plan.primaryLocale }) ?? previews.first {
            let fits = file.seconds >= 15 && file.seconds <= 30
            checks.append(GuidedCheck(
                id: "length",
                text: fits ? String(localized: "\(file.lengthTitle) · within Apple’s 15–30 seconds") : String(localized: "\(file.lengthTitle) · Apple takes 15–30 seconds"),
                state: fits ? .passed : .attention
            ))
        } else {
            checks.append(GuidedCheck(id: "length", text: String(localized: "Not made yet"), state: .attention))
        }
        for problem in Set(previews.flatMap(\.problems)).sorted() {
            checks.append(GuidedCheck(id: "problem-\(problem)", text: problem, state: .attention))
        }
        let still = run.tooStillMomentNames
        if !still.isEmpty {
            checks.append(GuidedCheck(
                id: "motion",
                text: String(localized: "Barely moves, even recorded again: \(still.formatted(.list(type: .and)))"),
                state: .attention
            ))
        }
        checks.append(GuidedCheck(id: "music", text: musicText(plan), state: .passed))
        let primary = GuidedMakeSummary.primaryName(plan)
        checks.append(GuidedCheck(
            id: "languages",
            text: plan.alsoMakes.previewLanguages == .all
                ? String(localized: "One per language")
                : String(localized: "\(primary); other languages show it"),
            state: .passed
        ))
        return checks
    }
}
