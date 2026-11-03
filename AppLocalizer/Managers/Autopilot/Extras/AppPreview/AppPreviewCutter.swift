//
//  AppPreviewCutter.swift
//  AppLocalizer
//

import Foundation

/// Picks each screen's moment from the recording. Screens play in the
/// plan's order; a screen without a mark is left out. A screen's moment
/// starts just after its mark, once the screen has settled, and ends just
/// before the next mark in time (or at the recording's end). The App
/// Preview's length, end card included, is shared out equally: a screen
/// with a shorter moment plays all of it and the others share what's
/// left. Every screen gets at least two seconds where its moment is that
/// long; when that would pass Apple's 30 seconds, screens are left out
/// from the end. Lengths are whole frames.
enum AppPreviewCutter {
    /// How long after its mark a screen has settled.
    static let settleSeconds = 0.3
    /// How long before the next mark a moment ends, so the next screen's
    /// transition never shows.
    static let leadOutSeconds = 0.1
    /// The least a screen plays when its moment is that long.
    static let minimumScreenSeconds = 2.0
    /// The end card's length when the screens fill the App Preview.
    static let standardEndCardSeconds = 3.0

    static func segments(
        marks: [AutopilotRecordingMark],
        recordingSeconds: Double,
        screenIDs: [String],
        spec: AppPreviewSpec,
        endCardSeconds: Double = standardEndCardSeconds
    ) -> [AppPreviewSegment] {
        var windows = moments(marks: marks, recordingSeconds: recordingSeconds, screenIDs: screenIDs, spec: spec)
        while !windows.isEmpty {
            let lengths = shares(of: windows, spec: spec, endCardSeconds: endCardSeconds)
            let total = lengths.reduce(0, +)
            if total + endCardSeconds <= spec.maximumSeconds + 0.0001 || windows.count == 1 {
                return zip(windows, lengths).map { AppPreviewSegment(screenID: $0.screenID, start: $0.start, duration: $1) }
            }
            windows.removeLast()
        }
        return []
    }

    /// The end card's length: three seconds, longer when the screens
    /// alone would leave the App Preview under Apple's 15 seconds.
    static func endCardSeconds(forSegmentsTotal total: Double, spec: AppPreviewSpec) -> Double {
        let seconds = max(standardEndCardSeconds, spec.minimumSeconds - total)
        return wholeFrames(seconds, spec: spec, roundingUp: true)
    }

    /// A length in whole frames.
    static func wholeFrames(_ seconds: Double, spec: AppPreviewSpec, roundingUp: Bool = false) -> Double {
        let fps = Double(max(spec.framesPerSecond, 1))
        let frames = roundingUp ? (seconds * fps - 0.000001).rounded(.up) : (seconds * fps + 0.000001).rounded(.down)
        return max(0, frames) / fps
    }

    // MARK: - Moments

    /// One screen's usable stretch of the recording.
    private struct Moment {
        var screenID: String
        var start: Double
        var available: Double
    }

    /// Each planned screen's moment, in the plan's order.
    private static func moments(marks: [AutopilotRecordingMark], recordingSeconds: Double, screenIDs: [String], spec: AppPreviewSpec) -> [Moment] {
        let inRecording = marks.filter { $0.seconds.isFinite && $0.seconds >= 0 && $0.seconds < recordingSeconds }
        let times = inRecording.map(\.seconds).sorted()
        var seen: Set<String> = []
        return screenIDs.compactMap { id in
            guard seen.insert(id).inserted, let mark = inRecording.filter({ $0.screenID == id }).min(by: { $0.seconds < $1.seconds }) else {
                return nil
            }
            let start = mark.seconds + settleSeconds
            let next = times.first { $0 > mark.seconds } ?? recordingSeconds
            let end = next < recordingSeconds ? next - leadOutSeconds : recordingSeconds
            let available = wholeFrames(end - start, spec: spec)
            guard available >= spec.frameSeconds else { return nil }
            return Moment(screenID: id, start: start, available: available)
        }
    }

    /// Shares the App Preview's length between the moments: equal parts,
    /// a short moment keeping all of itself and handing the rest on.
    private static func shares(of moments: [Moment], spec: AppPreviewSpec, endCardSeconds: Double) -> [Double] {
        var lengths = [Double?](repeating: nil, count: moments.count)
        var budget = max(0, spec.targetSeconds - endCardSeconds)
        var changed = true
        while changed {
            changed = false
            let open = lengths.indices.filter { lengths[$0] == nil }
            guard !open.isEmpty else { break }
            let share = budget / Double(open.count)
            for index in open where moments[index].available <= share {
                lengths[index] = moments[index].available
                budget -= moments[index].available
                changed = true
            }
        }
        let open = lengths.indices.filter { lengths[$0] == nil }
        let share = open.isEmpty ? 0 : budget / Double(open.count)
        return moments.indices.map { index in
            let length = lengths[index] ?? share
            let floor = min(minimumScreenSeconds, moments[index].available)
            return wholeFrames(max(length, floor), spec: spec)
        }
    }
}

extension AppPreviewCutter {
    /// The App Preview from the moments chosen at Pick, in the cut's order:
    /// each plays 6 seconds (all of it when it's shorter), with a 6-second
    /// end card. A revised length shares out what's left after the end
    /// card equally.
    static func segments(clips: [AppPreviewClip], cut: AppPreviewCut, spec: AppPreviewSpec) -> [AppPreviewSegment] {
        let byID = Dictionary(clips.map { ($0.screenID, $0) }, uniquingKeysWith: { first, _ in first })
        let order = cut.order(clips.map(\.screenID)).compactMap { byID[$0] }
        guard !order.isEmpty else { return [] }
        let endCard = AutopilotRecordingMoment.previewSeconds
        let share = cut.seconds.map { _ in max(spec.frameSeconds, (cut.targetSeconds - endCard) / Double(order.count)) }
            ?? AutopilotRecordingMoment.previewSeconds
        return order.compactMap { clip in
            let duration = wholeFrames(min(share, clip.seconds), spec: spec)
            guard duration >= spec.frameSeconds else { return nil }
            return AppPreviewSegment(screenID: clip.screenID, start: clip.start, duration: duration, source: clip.source)
        }
    }

    /// The end card after the chosen moments: 6 seconds, longer when the
    /// App Preview would be under Apple's 15 or under a revised length.
    static func momentsEndCardSeconds(forSegmentsTotal total: Double, cut: AppPreviewCut, spec: AppPreviewSpec) -> Double {
        let wanted = cut.seconds.map { _ in cut.targetSeconds - total } ?? AutopilotRecordingMoment.previewSeconds
        let seconds = max(AutopilotRecordingMoment.previewSeconds, wanted, spec.minimumSeconds - total)
        return wholeFrames(min(seconds, max(0, spec.maximumSeconds - total)), spec: spec, roundingUp: true)
    }
}
