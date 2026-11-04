//
//  MCPArtworkPreview+Motion.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The motion prompt's checks on the chosen header's animated pages, on
/// top of render_artwork's own: every animation repeats evenly in the
/// loop, frame 0 is the still the person chose, the last frame leads back
/// to it, the name and phrases never move, and no frame jumps from the
/// one before.
extension MCPArtworkPreview {
    /// How far frame 0 may be from the still, on average per channel.
    static let stillTolerance = 4.0
    /// The most two frames 1/30 s apart may differ, on average per channel.
    static let jumpThreshold = 10.0
    /// The width frames are compared at.
    static let motionCheckWidth = 480

    /// What's wrong with `motion`'s pages (empty when they loop cleanly),
    /// with `still` the concept's stills; `moving` names the pages whose
    /// data-al elements move (render_artwork found them).
    func motionProblems(_ motion: AutopilotArtworkDesign, still: AutopilotArtworkDesign?, moving: [AutopilotArtworkKind: [String]] = [:]) async
        -> [String]
    {
        var problems: [String] = []
        let loop = Double(AutopilotArtworkMotion.loopSeconds)
        let step = 1 / Double(AutopilotArtworkMotion.loopFramesPerSecond)
        let pages = AutopilotArtworkPages(context: session.context)
        let icon = await pages.icon()
        let locale = session.context.primaryLocale
        let phrases = await book().phraseTexts(locale: locale.code)
        for kind in session.run.plan.artworkKinds {
            guard let html = motion.page(for: kind) else { continue }
            if let marks = moving[kind], !marks.isEmpty {
                problems.append(String(localized: "The \(kind.rawValue) loop moves \(marks.formatted(.list(type: .and))): data-al elements never move."))
            }
            let request = await pages.request(
                html: html, kind: kind, locale: locale, headline: "", run: session.run, icon: icon, pixelWidth: Self.motionCheckWidth,
                phrases: phrases
            )
            do {
                let frames = try await ArtworkWebRenderer.shared.withLoadedPage(request) { page, measure in
                    let jumps = measure.motionsThatMayJump(loopSeconds: loop)
                    let first = try await page.frame(at: 0, width: Self.motionCheckWidth)
                    let last = try await page.frame(at: loop - step, width: Self.motionCheckWidth)
                    var steps: [(Double, CGImage, CGImage)] = []
                    for second in stride(from: 1.0, to: loop, by: 2.5) {
                        let before = try await page.frame(at: second, width: Self.motionCheckWidth)
                        let after = try await page.frame(at: second + step, width: Self.motionCheckWidth)
                        steps.append((second, before, after))
                    }
                    return (jumps.count, first, last, steps)
                }
                if frames.0 > 0 {
                    problems.append(String(localized: """
                    The \(kind.rawValue) page has \(frames.0) animation(s) whose duration doesn’t divide \(AutopilotArtworkMotion.loopSeconds) s evenly.
                    """))
                }
                if let gap = ArtworkLoopChecker.difference(frames.1, frames.2), gap > ArtworkLoopChecker.seamTolerance {
                    problems.append(String(localized: "The \(kind.rawValue) loop’s last frame doesn’t lead back to frame 0, so it jumps when it repeats."))
                }
                if let jump = frames.3.first(where: { (ArtworkLoopChecker.difference($0.1, $0.2) ?? 0) > Self.jumpThreshold }) {
                    let second = jump.0.formatted(.number.precision(.fractionLength(1)))
                    problems.append(String(localized: "The \(kind.rawValue) loop jumps from one frame to the next at \(second) s: keep every move slow and continuous."))
                }
                if let stillPage = still?.page(for: kind),
                   let difference = await stillDifference(stillPage, frame: frames.1, kind: kind, icon: icon, phrases: phrases),
                   difference > Self.stillTolerance
                {
                    problems.append(String(localized: "The \(kind.rawValue) loop’s frame 0 isn’t the still the person chose: time 0 is the poster."))
                }
            } catch {
                problems.append(String(localized: "The \(kind.rawValue) loop didn’t render: \(error.localizedDescription)"))
            }
        }
        return problems
    }

    /// How far `frame` is from `html`'s still.
    private func stillDifference(_ html: String, frame: CGImage, kind: AutopilotArtworkKind, icon: Data?, phrases: [String: String]) async -> Double? {
        let pages = AutopilotArtworkPages(context: session.context)
        let request = await pages.request(
            html: html, kind: kind, locale: session.context.primaryLocale, headline: "", run: session.run, icon: icon,
            pixelWidth: Self.motionCheckWidth, phrases: phrases
        )
        guard let still = try? await ArtworkWebRenderer.shared.withLoadedPage(request, { page, _ in
            try await page.frame(at: 0, width: Self.motionCheckWidth)
        }) else { return nil }
        return ArtworkLoopChecker.difference(still, frame)
    }
}
