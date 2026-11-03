//
//  AutopilotPlan+DuoPoses.swift
//  AppLocalizer
//

import Foundation

/// iPhone Duo's screenshots, from the plan's iPhone Duo row: the inner
/// display (unfolded, the default), the cover display (folded), or both,
/// side by side in each image or as separate screenshots. Every image is
/// Apple's 2007 × 2853; a cover display is framed inside it. The screens
/// are the set's, so the steps are the same as on iPhone.
extension AutopilotPlan {
    /// Apple takes at most 10 screenshots a device.
    static let duoShotLimit = 10

    var plansDuo: Bool { displayTypes.contains(.iPhoneDuo) }

    /// What iPhone Duo's screenshots show; the inner display in plans
    /// from before the row.
    var duoScreens: AutopilotDuoScreens { runChoice.duoScreens ?? .inner }

    /// How both displays appear; side by side unless chosen.
    var duoBoth: AutopilotDuoBoth { runChoice.duoBoth ?? .sideBySide }

    /// The screens that get a separate cover screenshot: as many as fit
    /// under Apple's 10 with every screen's inner one.
    var duoSeparateCovers: Int {
        max(0, min(screens.count, Self.duoShotLimit - screens.count))
    }

    /// iPhone Duo's screenshots in the set's order.
    var duoShots: [AutopilotDuoShot] {
        let slots = Array(screens.indices)
        switch (duoScreens, duoBoth) {
        case (.inner, _):
            return slots.map { AutopilotDuoShot(screenSlot: $0, poses: [.open]) }
        case (.cover, _):
            return slots.map { AutopilotDuoShot(screenSlot: $0, poses: [.closed]) }
        case (.both, .sideBySide):
            return slots.map { AutopilotDuoShot(screenSlot: $0, poses: [.open, .closed]) }
        case (.both, .separate):
            let covers = duoSeparateCovers
            return slots.flatMap { slot in
                [AutopilotDuoShot(screenSlot: slot, poses: [.open])]
                    + (slot < covers ? [AutopilotDuoShot(screenSlot: slot, poses: [.closed])] : [])
            }
        }
    }

    /// The poses a screen (by set slot) is captured in on iPhone Duo:
    /// open, closed, or both.
    func duoPoses(forSlot slot: Int) -> [AutopilotDuoPose] {
        let poses = Set(duoShots.filter { $0.screenSlot == slot }.flatMap(\.poses))
        return AutopilotDuoPose.allCases.filter(poses.contains)
    }

    /// The pose a target is captured in; nil off iPhone Duo. A target from
    /// before poses were kept takes its screen's first.
    func duoPose(for target: AutopilotCaptureTarget) -> AutopilotDuoPose? {
        guard target.displayType == .iPhoneDuo else { return nil }
        if let pose = target.duoPose { return pose }
        guard let slot = slot(of: target.screenID) else { return nil }
        return duoPoses(forSlot: slot).first
    }

    /// Whether a capture fits its target's pose: off iPhone Duo always; a
    /// closed one takes only the cover display, an open one anything else.
    func fits(_ capture: AutopilotCapture) -> Bool {
        guard let pose = duoPose(for: capture.target) else { return true }
        let isCover = CaptureSizeRules.isDuoOuterDisplay(capture.pixelSize)
        return pose == .closed ? isCover : !isCover
    }

    /// The set slots iPhone Duo captures in a pose, 0-based.
    func duoSlots(_ pose: AutopilotDuoPose) -> [Int] {
        screens.indices.filter { duoPoses(forSlot: $0).contains(pose) }
    }

    /// The target a capture of `size` is for: on iPhone Duo, the screen's
    /// only pose, or when it's captured in both, the display the capture
    /// shows (the cover display's size is closed).
    func resolvedTarget(_ target: AutopilotCaptureTarget, size: PixelSize) -> AutopilotCaptureTarget {
        guard target.displayType == .iPhoneDuo, let slot = slot(of: target.screenID) else { return target }
        let poses = duoPoses(forSlot: slot)
        var resolved = target
        if poses.count > 1 {
            resolved.duoPose = CaptureSizeRules.isDuoOuterDisplay(size) ? .closed : .open
        } else {
            resolved.duoPose = poses.first ?? target.duoPose
        }
        return resolved
    }

    /// iPhone Duo's capture targets for one screen in one language.
    func duoTargets(screenID: String, locale: String) -> [AutopilotCaptureTarget] {
        guard let slot = slot(of: screenID) else { return [] }
        return duoPoses(forSlot: slot).map {
            AutopilotCaptureTarget(screenID: screenID, displayType: .iPhoneDuo, locale: locale, duoPose: $0)
        }
    }
}
