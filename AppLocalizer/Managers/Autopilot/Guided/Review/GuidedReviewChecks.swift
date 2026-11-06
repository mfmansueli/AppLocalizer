//
//  GuidedReviewChecks.swift
//  AppLocalizer
//

import Foundation

/// The checks beside each part in Review & push, from what the run
/// recorded: the languages checked, the captions shortened (each language's
/// to confirm), right-to-left, the captures' text, the artwork's languages
/// and loop, the App Preview's length, music and languages.
enum GuidedReviewChecks {
    static func checks(for part: GuidedReviewPart, run: AutopilotRun, previews: [ExtrasPreviewFile] = []) -> [GuidedCheck] {
        switch part {
        case .screenshots: screenshots(run)
        case .artwork: artwork(run)
        case .appPreview: appPreview(run, previews: previews)
        }
    }

    /// Checks still waiting on the person: shortenings not confirmed yet.
    static func toConfirm(in run: AutopilotRun) -> [GuidedCheck] {
        screenshots(run).filter { $0.state == .toConfirm }
    }

    // MARK: - Screenshots

    private static func screenshots(_ run: AutopilotRun) -> [GuidedCheck] {
        let plan = run.plan
        var checks: [GuidedCheck] = []
        let total = plan.localeCodes.count
        let checked = plan.localeCodes.count { run.localeStatus[$0]?.isDone == true }
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

    /// The final captures: in the right language, nothing cut off, no
    /// system prompt, not mostly blank; and which problems were captured
    /// again or kept as they were (MB Admin's said "2 problems were fixed
    /// and captured again" when one was kept).
    private static func captureCheck(_ run: AutopilotRun) -> GuidedCheck {
        let withIssues = run.plan.targets.compactMap(run.finalCapture(for:)).count { !run.textIssues(of: $0).isEmpty }
        if withIssues > 0 {
            return GuidedCheck(
                id: "captures", text: withIssues == 1
                    ? String(localized: "1 capture to look at: open Pick or the captures to see what")
                    : String(localized: "\(withIssues) captures to look at: open Pick or the captures to see what"),
                state: .attention
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

    // MARK: - Header and search

    private static func artwork(_ run: AutopilotRun) -> [GuidedCheck] {
        let plan = run.plan
        let progress = run.extrasProgress
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

    // MARK: - App Preview

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
        let music = plan.alsoMakes.previewMusic
        checks.append(GuidedCheck(
            id: "music",
            text: music.track == .ownFile
                ? String(localized: "Music: \(music.title) · you confirmed the rights")
                : String(localized: "Music: \(music.title) · from AppLocalizer’s library"),
            state: .passed
        ))
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
