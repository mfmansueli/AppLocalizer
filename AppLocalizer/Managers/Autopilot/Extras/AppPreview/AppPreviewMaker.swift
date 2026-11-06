//
//  AppPreviewMaker.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Makes one App Preview from a Simulator recording: cuts each planned
/// screen's moment (in the cut's order, to its length), styles it like the
/// screenshots with the screen's caption, ends on the app's name, writes
/// the movie with its music under it, then reads the file back and lists
/// anything App Store Connect would refuse. Runs off the main actor.
enum AppPreviewMaker {
    static func make(_ request: AppPreviewRequest) async throws -> AppPreviewResult {
        guard var spec = AppPreviewSpec.spec(for: request.displayType, landscape: request.recordingSize.isLandscape) else {
            throw AppPreviewError.noSpec(request.displayType)
        }
        spec.targetSeconds = request.cut.targetSeconds
        var segments: [AppPreviewSegment]
        let momentEnds: [String: Double]
        if let clips = request.clips {
            segments = AppPreviewCutter.segments(clips: clips, cut: request.cut, spec: spec)
            momentEnds = Dictionary(clips.map { ($0.screenID, $0.end) }, uniquingKeysWith: { first, _ in first })
        } else {
            let screenIDs = request.cut.order(request.screens.map(\.id))
            segments = AppPreviewCutter.segments(marks: request.marks, recordingSeconds: request.recordingSeconds, screenIDs: screenIDs, spec: spec)
            momentEnds = Dictionary(
                AutopilotRecordingMoment.marked(request.marks, recordingSeconds: request.recordingSeconds, screenIDs: screenIDs).map { ($0.screenID, $0.end) },
                uniquingKeysWith: { first, _ in first }
            )
        }
        guard !segments.isEmpty else { throw AppPreviewError.noUsableMark }
        segments = await AppPreviewSettler.settled(segments, recording: request.recording, momentEnds: momentEnds, spec: spec)
        let segmentsTotal = segments.map(\.duration).reduce(0, +)
        let endCardSeconds = request.clips == nil
            ? AppPreviewCutter.endCardSeconds(forSegmentsTotal: segmentsTotal, spec: spec)
            : AppPreviewCutter.momentsEndCardSeconds(forSegmentsTotal: segmentsTotal, cut: request.cut, spec: spec)
        let styler = AppPreviewStyler(
            template: request.template, locale: request.locale, spec: spec, recordingSize: request.recordingSize, fonts: request.fonts,
            captionScale: request.cut.captionScaleValue
        )
        let headlines = Dictionary(request.screens.map { ($0.id, $0.headline) }, uniquingKeysWith: { first, _ in first })
        let frames = try segments.map { try styler.frame(headline: headlines[$0.screenID] ?? "") }
        let endCardLine = request.cut.showsEndCardCaption ? headlines[request.cut.endCardScreenID ?? segments[0].screenID] ?? "" : ""
        let endCard = try styler.endCard(appName: request.appName, headline: endCardLine)
        try Task.checkCancellation()
        let total = segments.map(\.duration).reduce(0, +) + endCardSeconds
        var soundtrack: AppPreviewSoundtrack?
        if let music = request.music { soundtrack = try await AppPreviewSoundtrack.make(music, seconds: total) }
        let assembler = AppPreviewAssembler(spec: spec, appRect: styler.appRect, appCornerRadius: styler.appCornerRadius)
        let output = try await assembler.assemble(
            recording: request.recording, segments: segments, frames: frames, endCard: endCard, endCardSeconds: endCardSeconds, output: request.output,
            soundtrack: soundtrack
        )
        let facts = await AppPreviewInspector.facts(of: output.url)
        var issues = facts?.issues(against: spec) ?? [String(localized: "The App Preview was written but can't be read back to check it.")]
        issues += captionIssues(segments: segments, headlines: headlines, styler: styler)
        return AppPreviewResult(
            output: output, spec: spec, posterTimeCode: spec.posterTimeCode, facts: facts, issues: issues, segments: segments,
            endCardSeconds: endCardSeconds
        )
    }

    /// A sentence for each caption that doesn't fit its band.
    private static func captionIssues(segments: [AppPreviewSegment], headlines: [String: String], styler: AppPreviewStyler) -> [String] {
        segments.compactMap { segment in
            let headline = headlines[segment.screenID] ?? ""
            let fit = styler.captionFit(for: headline)
            guard !fit.isEmpty, !fit.fits else { return nil }
            return String(localized: "The caption “\(headline)” doesn't fit the App Preview's band on two lines and is cut off. Shorten it.")
        }
    }
}
