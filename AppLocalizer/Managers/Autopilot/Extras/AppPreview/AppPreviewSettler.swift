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
/// first. It looks at a segment's first seconds: when its opening frame is
/// much blanker (`CaptureBlankness`) than a later one, the segment starts
/// on the first frame about as full as the fullest, keeping its length
/// where its moment has room after it, and its end otherwise.
enum AppPreviewSettler {
    /// How far into a segment it looks, at most half the segment: MB
    /// Admin's recording showed its loading list for 3.5–5 s after each
    /// launch (blank share 0.33–0.46, then 0.04 once filled).
    static let window = 3.0
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
        return settled
    }

    /// How far into the frames looked at (`step` apart) the screen has
    /// filled in; 0 when it opens filled in, or nothing could be read.
    static func offset(blankShares: [Double?]) -> Double {
        guard let opening = blankShares.first ?? nil, let fullest = blankShares.compactMap(\.self).min(), opening - fullest >= blankerBy else {
            return 0
        }
        let index = blankShares.firstIndex { ($0 ?? 1) <= fullest + fullEnough } ?? 0
        return Double(index) * step
    }

    /// `segment` starting `offset` later, rounded up to whole frames so it
    /// never starts before the screen has filled in: as long as
    /// before when its moment has room, else ending where it did.
    static func moved(_ segment: AppPreviewSegment, by offset: Double, momentEnd: Double?, spec: AppPreviewSpec) -> AppPreviewSegment {
        var moved = segment
        moved.start = segment.start + AppPreviewCutter.wholeFrames(offset, spec: spec, roundingUp: true)
        if let momentEnd, moved.start + segment.duration <= momentEnd + 0.0001 { return moved }
        moved.duration = AppPreviewCutter.wholeFrames(max(spec.frameSeconds, segment.end - moved.start), spec: spec)
        return moved
    }

    /// Each frame's blank share over the segment's first seconds.
    private static func blankShares(of segment: AppPreviewSegment, in url: URL) async -> [Double?] {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 0)
        let tolerance = CMTime(value: 1, timescale: 60)
        generator.requestedTimeToleranceBefore = tolerance
        generator.requestedTimeToleranceAfter = tolerance
        let span = min(window, segment.duration / 2)
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
