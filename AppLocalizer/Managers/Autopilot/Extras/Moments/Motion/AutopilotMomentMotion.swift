//
//  AutopilotMomentMotion.swift
//  AppLocalizer
//

import Foundation

/// How much a moment of an App Preview recording moves, from the share of
/// its pixels that changed every `step` seconds. Bruma's App Preview looked
/// like a slideshow: Nearby's 6 s changed at most 0.1% of its pixels at any
/// step, and the others held still between the flashes of a relaunch.
struct AutopilotMomentMotion: Codable, Hashable, Sendable {
    /// 0–1: the share of its steps in which something moved.
    var movingShare: Double
    /// The longest stretch in which nothing did.
    var stillSeconds: Double

    /// Between the frames compared.
    static let step = 0.25
    /// A step moved when this share of the pixels changed; a clock ticking
    /// is out of the frame compared, and a cursor blinking stays below.
    static let movedShare = 0.003
    /// A step this different is a cut (a relaunch, the white launch
    /// screen), not motion.
    static let cutShare = 0.85
    /// A moment moves for at least this share of its steps.
    static let fewestMoving = 0.3
    /// Nothing moving for longer than this reads as a still image.
    static let longestStill = 3.5

    var isTooStill: Bool {
        movingShare < Self.fewestMoving || stillSeconds > Self.longestStill
    }

    init(movingShare: Double, stillSeconds: Double) {
        self.movingShare = movingShare
        self.stillSeconds = stillSeconds
    }

    /// From each step's changed share. A cut counts for neither side and
    /// ends a still stretch.
    init(changes: [Double]) {
        let steps = changes.filter { $0 <= Self.cutShare }
        let moving = steps.count { $0 > Self.movedShare }
        var longest = 0
        var run = 0
        for change in changes {
            run = change <= Self.movedShare ? run + 1 : 0
            longest = max(longest, run)
        }
        movingShare = steps.isEmpty ? 0 : Double(moving) / Double(steps.count)
        stillSeconds = Double(longest) * Self.step
    }
}
