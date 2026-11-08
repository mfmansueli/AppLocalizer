//
//  AppPreviewSettler.swift
//  AppLocalizer
//

import AVFoundation
import CoreGraphics
import Foundation

/// Starts each moment once its screen has filled in. MB Admin's App
/// Preview opened on an empty list still loading ("nenhum produto na
/// fila", 0 of 60) for its first second, the frame the App Store autoplays
/// first. It looks at a segment's first seconds: when an early frame is
/// much blanker (`CaptureBlankness`) than a later one, the segment starts
/// on the first frame about as full as what follows, keeping its length
/// where its moment has room after it, and its end otherwise.
enum AppPreviewSettler {
    /// How far into a segment a launch or a load may begin: MB Admin's
    /// recording showed its loading list for 3.5–5 s after each launch
    /// (blank share 0.33–0.46, then 0.04 once filled).
    static let window = 3.0
    /// How far it looks for the screen to fill in, at most the segment
    /// less a second (`span(of:)`). Bruma's Match moment opened 0.25 s
    /// before its relaunch: the Home Screen (0.02), the white launch screen
    /// until 2.25 s (0.88–1.00), the match fading in at 2.5 s (0.10).
    static let settleWindow = 6.0
    /// Between the frames it looks at.
    static let step = 0.25
    /// How much blanker the opening must be than the fullest frame.
    static let blankerBy = 0.15
    /// Close enough to the fullest frame to start on.
    static let fullEnough = 0.05

    /// The segments, each starting once its screen has filled in.
    /// `momentEnds` is where each screen's moment ends in its file.
    static func settled(
        _ segments: [AppPreviewSegment], recording: URL, momentEnds: [String: Double], spec: AppPreviewSpec
    ) async -> [AppPreviewSegment] {
        var settled: [AppPreviewSegment] = []
        for segment in segments {
            let shares = await blankShares(of: segment, in: segment.source ?? recording)
            let offset = offset(blankShares: shares)
            settled.append(offset > 0 ? moved(segment, by: offset, momentEnd: momentEnds[segment.screenID], spec: spec) : segment)
        }
        let lost = zip(segments, settled).map { $0.duration - $1.duration }.reduce(0, +)
        return refilled(settled, lost: lost, momentEnds: momentEnds, spec: spec)
    }

    /// How far into the frames looked at (`step` apart) the screen has
    /// filled in: after the last frame in the first `window` much blanker
    /// than the fullest (a launch screen, a list still loading), once about
    /// as full as what follows it gets. Bruma's Match moment opened on the
    /// Home Screen, its other apps showing, then the white launch screen:
    /// the Home Screen, emptier than the match, set the bar, and the match
    /// came after the frames looked at, so it was kept. 0 when nothing is
    /// blanker, or nothing could be read.
    static func offset(blankShares: [Double?]) -> Double {
        guard let fullest = blankShares.compactMap(\.self).min() else { return 0 }
        let blankWithin = Int((window / step).rounded())
        var start = 0
        for (index, share) in blankShares.enumerated() where index <= blankWithin && (share ?? 0) - fullest >= blankerBy {
            let after = blankShares.indices.dropFirst(index + 1)
            // Only a blank frame a filled-in one follows: a screen that
            // turns blank and stays (a photo vanishing once seen) keeps its
            // start.
            guard let settled = after.compactMap({ blankShares[$0] }).min(), settled - fullest < blankerBy else { continue }
            if let filled = after.first(where: { (blankShares[$0] ?? 1) <= settled + fullEnough }) { start = filled }
        }
        return Double(start) * step
    }

    /// How far into a segment of `duration` seconds it looks: up to
    /// `settleWindow`, leaving a second of it (half of a shorter one).
    static func span(of duration: Double) -> Double {
        min(settleWindow, max(duration / 2, duration - 1))
    }

    /// `segment` starting `offset` later, rounded up to whole frames so it
    /// never starts before the screen has filled in: as long as
    /// before when its moment has room, else ending with its moment (or
    /// where it did, when that's later).
    static func moved(_ segment: AppPreviewSegment, by offset: Double, momentEnd: Double?, spec: AppPreviewSpec) -> AppPreviewSegment {
        var moved = segment
        moved.start = segment.start + AppPreviewCutter.wholeFrames(offset, spec: spec, roundingUp: true)
        if let momentEnd, moved.start + segment.duration <= momentEnd + 0.0001 { return moved }
        let end = max(segment.end, momentEnd ?? segment.end)
        moved.duration = AppPreviewCutter.wholeFrames(max(spec.frameSeconds, end - moved.start), spec: spec)
        return moved
    }

    /// The seconds the segments that couldn't keep their length `lost`,
    /// shared out among those whose moments go on after them, whole frames
    /// each. Without it the end card took them: Bruma's iPad Match lost
    /// 2.4 s to its relaunch and the end card ran 8.4 s of 24.
    static func refilled(_ segments: [AppPreviewSegment], lost: Double, momentEnds: [String: Double], spec: AppPreviewSpec) -> [AppPreviewSegment] {
        let fps = Double(max(spec.framesPerSecond, 1))
        func room(_ segment: AppPreviewSegment) -> Int {
            let end = momentEnds[segment.screenID] ?? segment.end
            return max(0, Int(((end - segment.end) * fps + 0.000001).rounded(.down)))
        }
        var segments = segments
        var left = Int((lost * fps + 0.000001).rounded(.down))
        while left > 0 {
            let open = segments.indices.filter { room(segments[$0]) > 0 }
            guard !open.isEmpty else { break }
            let share = max(1, left / open.count)
            for index in open where left > 0 {
                let taken = min(share, room(segments[index]), left)
                segments[index].duration = AppPreviewCutter.wholeFrames(segments[index].duration + Double(taken) / fps, spec: spec)
                left -= taken
            }
        }
        return segments
    }

    /// Each frame's blank share over the segment's first seconds.
    private static func blankShares(of segment: AppPreviewSegment, in url: URL) async -> [Double?] {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 0)
        let tolerance = CMTime(value: 1, timescale: 60)
        generator.requestedTimeToleranceBefore = tolerance
        generator.requestedTimeToleranceAfter = tolerance
        let span = span(of: segment.duration)
        var shares: [Double?] = []
        var time = 0.0
        while time <= span + 0.0001 {
            let image = try? await generator.image(at: CMTime(seconds: segment.start + time, preferredTimescale: 600)).image
            shares.append(image.flatMap(CaptureBlankness.largestBlankShare(of:)))
            time += step
        }
        return shares
    }
}
