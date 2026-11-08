//
//  GuidedReviewChecksTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Review & push's checks beside each part, and the languages it shows
/// side by side.
@MainActor
@Suite("GuidedReviewChecks")
struct GuidedReviewChecksTests {
    private static func check(_ id: String, in checks: [GuidedCheck]) -> GuidedCheck? {
        checks.first { $0.id == id }
    }

    @Test func aMomentThatStayedStillIsCalledOut() throws {
        #expect(Self.check("motion", in: GuidedReviewChecks.checks(for: .appPreview, run: StudioDebugPick.picking())) == nil)

        var run = StudioDebugPick.picking()
        run.noteMotion([run.plan.screens[1].id: AutopilotMomentMotion(movingShare: 0, stillSeconds: 6)])
        let check = try #require(Self.check("motion", in: GuidedReviewChecks.checks(for: .appPreview, run: run)))
        #expect(check.state == .attention)
        #expect(check.text == "Barely moves, even recorded again: Week")
    }

    @Test func theMusicSaysWhereItCameFrom() {
        var run = StudioDebugPick.picking()
        run.plan.alsoMakes.suggestedMusic = AppMusicPick(track: .softAmbient, reason: "Quiet")
        let picked = Self.check("music", in: GuidedReviewChecks.checks(for: .appPreview, run: run))
        #expect(picked?.text == "Music: Soft ambient · picked for this app")

        run.plan.alsoMakes.music = AutopilotPreviewMusic(track: .calmPiano)
        let chosen = Self.check("music", in: GuidedReviewChecks.checks(for: .appPreview, run: run))
        #expect(chosen?.text == "Music: Calm piano · from AppLocalizer’s library")
    }

    @Test func aShortenedCaptionWaitsForLooksGood() throws {
        var run = StudioDebugRuns.run(.ready)
        let checks = GuidedReviewChecks.checks(for: .screenshots, run: run)
        let total = run.plan.localeCodes.count
        #expect(Self.check("fits", in: checks)?.text == "Every caption fits in \(total - 1) languages as written")
        let short = try #require(Self.check("short-de-DE", in: checks))
        #expect(short.text == "German: 1 caption was shortened by Claude Code")
        #expect(short.state == .toConfirm)
        #expect(GuidedReviewChecks.toConfirm(in: run).count == 1)

        var review = AutopilotGuidedReview()
        review.confirm(short.shortenings)
        run.guidedReview = review
        #expect(Self.check("short-de-DE", in: GuidedReviewChecks.checks(for: .screenshots, run: run))?.state == .passed)
        #expect(GuidedReviewChecks.toConfirm(in: run).isEmpty)
    }

    @Test func languagesNotCheckedYetNeedALook() {
        let run = StudioDebugRuns.run(.localize)
        let fits = Self.check("fits", in: GuidedReviewChecks.checks(for: .screenshots, run: run))
        #expect(fits?.state == .attention)
        #expect(fits?.text.hasSuffix("languages checked") == true)
    }

    @Test func theCapturesTextIsChecked() {
        var run = StudioDebugRuns.run(.ready)
        let withIssues = run.plan.targets.compactMap(run.finalCapture(for:)).count { !run.textIssues(of: $0).isEmpty }
        let flagged = Self.check("captures", in: GuidedReviewChecks.checks(for: .screenshots, run: run))
        if withIssues > 0 {
            #expect(flagged?.state == .attention)
            #expect(flagged?.text.contains("to look at") == true, "\(flagged?.text ?? "")")
        }

        for index in run.captures.indices { run.captures[index].text = nil }
        run.problems = []
        let clean = Self.check("captures", in: GuidedReviewChecks.checks(for: .screenshots, run: run))
        #expect(clean?.state == .passed)
        #expect(clean?.text == "No alert, prompt, cut-off text or blank screen in any capture")
    }

    /// MB Admin's said "2 problems were fixed and captured again" when the
    /// person kept one capture as it was.
    @Test func keptCapturesArentCalledFixed() throws {
        var run = StudioDebugRuns.run(.ready)
        for index in run.captures.indices { run.captures[index].text = nil }
        let target = try #require(run.plan.targets.first)
        let problem = AutopilotProblem(id: "p1", target: target, what: "Portrait iPad", proposedFix: nil, reportedAt: .now)
        var captured = problem
        captured.id = "p2"
        captured.resolution = .captured
        var kept = problem
        kept.resolution = .keptCapture
        run.problems = [captured, kept]
        #expect(Self.check("captures", in: GuidedReviewChecks.checks(for: .screenshots, run: run))?.text
            == "No alert, prompt, cut-off text or blank screen · 1 problem was fixed and captured again, 1 capture was kept as it was")

        run.problems = [kept]
        #expect(Self.check("captures", in: GuidedReviewChecks.checks(for: .screenshots, run: run))?.text
            == "No alert, prompt, cut-off text or blank screen · 1 capture was kept as it was")
    }

    @Test func aMostlyBlankCaptureNeedsALook() throws {
        var run = StudioDebugRuns.run(.ready)
        for index in run.captures.indices { run.captures[index].text = nil }
        run.problems = []
        let target = try #require(run.plan.targets.first)
        for index in run.captures.indices where run.captures[index].target == target {
            run.captures[index].text = CaptureTextFacts(blankShare: 0.77)
        }
        let check = Self.check("captures", in: GuidedReviewChecks.checks(for: .screenshots, run: run))
        #expect(check?.state == .attention)
        #expect(check?.text == "1 capture to look at: click its screen to see it larger")
        let language = StoreLocaleCatalog.locale(code: target.locale)?.shortName ?? ""
        let screen = run.plan.screens.first { $0.id == target.screenID }?.name ?? ""
        #expect(check?.details == [
            "\(language) · \(target.displayType.shortTitle) · \(screen): 77% of the screen is blank: an empty state, or a screen still loading.",
        ])
    }

    /// Bruma's run: 22 captures, and the check said to open Pick, which its
    /// steps didn't have.
    @Test func manyCapturesToLookAtAreListedUpToALimit() {
        var run = StudioDebugRuns.run(.ready)
        run.problems = []
        for index in run.captures.indices { run.captures[index].text = CaptureTextFacts(blankShare: 0.9) }
        let flagged = run.plan.targets.compactMap(run.finalCapture(for:)).count
        #expect(flagged > GuidedReviewChecks.detailLines)
        let check = Self.check("captures", in: GuidedReviewChecks.checks(for: .screenshots, run: run))
        #expect(check?.text == "\(flagged) captures to look at: click a screen to see it larger")
        #expect(check?.details.count == GuidedReviewChecks.detailLines + 1)
        #expect(check?.details.last == "and \(flagged - GuidedReviewChecks.detailLines) more")
        #expect(check?.text.contains("Pick") == false)
    }

    @Test func theHeaderIsMadeInEveryLanguage() {
        let run = StudioDebugGuided.ready(approved: [])
        let checks = GuidedReviewChecks.checks(for: .artwork, run: run)
        #expect(Self.check("made", in: checks)?.text == "Made in every language: \(run.plan.localeCodes.count)")
        #expect(Self.check("texts", in: checks)?.state == .passed)
        #expect(checks.allSatisfy { $0.state == .passed })
    }

    /// Bruma's log said "Artwork checks: 24 warnings, nothing that blocks
    /// the push" while Review showed every check passed.
    @Test func whatTheArtworksChecksFoundIsSaid() {
        let run = StudioDebugExtras.checked(StudioDebugGuided.ready(approved: []))
        let found = Self.check("findings", in: GuidedReviewChecks.checks(for: .artwork, run: run))
        #expect(found?.state == .attention)
        #expect(found?.text == "1 error keeps that image out of the push")
        #expect(found?.details == StudioDebugExtras.checks.map(\.text))

        var warnings = run
        warnings.extrasProgress?.artworkChecks = [StudioDebugExtras.checks[1]]
        #expect(Self.check("findings", in: GuidedReviewChecks.checks(for: .artwork, run: warnings))?.text
            == "1 warning to look at; it doesn’t keep anything out of the push")
        warnings.extrasProgress?.artworkChecks = []
        #expect(Self.check("findings", in: GuidedReviewChecks.checks(for: .artwork, run: warnings)) == nil)
    }

    @Test func aHeaderNotMadeSaysWhy() {
        let checks = GuidedReviewChecks.checks(for: .artwork, run: StudioDebugHeaderStyle.headerNotMade)
        let made = Self.check("made", in: checks)
        #expect(made?.state == .attention)
        #expect(made?.text.hasPrefix("Couldn’t render the header page") == true)
        #expect(Self.check("loop", in: checks)?.text == "\(AutopilotArtworkMotion.loopSeconds)-second loop · plays muted on repeat")
    }

    @Test func anAppPreviewNotMadeYetNeedsALook() {
        let run = StudioDebugGuided.ready(approved: [])
        let checks = GuidedReviewChecks.checks(for: .appPreview, run: run, previews: [])
        #expect(Self.check("length", in: checks)?.text == "Not made yet")
        #expect(Self.check("length", in: checks)?.state == .attention)
        #expect(Self.check("languages", in: checks)?.text == "English (U.S.); other languages show it")
        #expect(Self.check("music", in: checks)?.text.hasPrefix("Music: ") == true)
    }

    // MARK: - Languages side by side

    @Test func theLanguagesMostLikelyToShowAProblemComeFirst() {
        let codes = ["en-US", "fr-FR", "de-DE", "es-ES", "ja", "ar-SA", "it"]
        #expect(GuidedPreviewLocales.pick(from: codes, primary: "en-US") == ["en-US", "de-DE", "ja", "ar-SA"])
    }

    /// The sample's languages are sorted by name (Arabic, Chinese, Dutch…):
    /// the switch still says English, German, Japanese, Arabic, as the
    /// board does.
    @Test func eachGroupsOwnOrderWinsOverTheRuns() {
        let codes = ["ar-SA", "zh-Hans", "nl-NL", "en-US", "fr-FR", "de-DE", "it", "ja", "ko"]
        #expect(GuidedPreviewLocales.pick(from: codes, primary: "en-US") == ["en-US", "de-DE", "ja", "ar-SA"])
    }

    @Test func theRestFillTheSegmentsInOrder() {
        #expect(GuidedPreviewLocales.pick(from: ["en-US", "de-DE", "fr-FR"], primary: "de-DE") == ["de-DE", "en-US", "fr-FR"])
        #expect(GuidedPreviewLocales.pick(from: ["en-US"], primary: "en-US") == ["en-US"])
    }

    @Test func aLanguageIsItsCodesFirstPart() {
        #expect(GuidedPreviewLocales.language(of: "zh-Hans") == "zh")
        #expect(GuidedPreviewLocales.language(of: "pt-BR") == "pt")
        #expect(GuidedPreviewLocales.language(of: "ja") == "ja")
    }
}
#endif
