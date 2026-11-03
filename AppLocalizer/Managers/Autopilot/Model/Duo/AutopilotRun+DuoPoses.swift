//
//  AutopilotRun+DuoPoses.swift
//  AppLocalizer
//

import Foundation

extension AutopilotRun {
    /// How iPhone Duo should be for the screens left to capture: closed
    /// while closed screens are left, then open; nil when it has none. A
    /// problem with the Duo itself (closed, stuck) holds every screen on it,
    /// but that's what the watcher fixes, so those still count; a problem
    /// with one screen leaves that screen out.
    var duoPoseWanted: AutopilotDuoPose? {
        guard stage == .capture || stage == .waiting else { return nil }
        let held = heldTargets(byDevices: false)
        let left = plan.targets.filter { $0.displayType == .iPhoneDuo && !isSettled($0) && !held.contains($0) }
        let poses = Set(left.compactMap(plan.duoPose(for:)))
        if poses.contains(.closed) { return .closed }
        return poses.contains(.open) ? .open : nil
    }
}

extension AutopilotRun {
    /// Runs from before iPhone Duo's targets kept a pose: each Duo capture
    /// takes the one its size shows, and each problem its screen's first,
    /// so they still count for the plan's targets.
    func withDuoPoses() -> AutopilotRun {
        var run = self
        for index in run.captures.indices where run.captures[index].target.displayType == .iPhoneDuo && run.captures[index].target.duoPose == nil {
            let capture = run.captures[index]
            run.captures[index].target.duoPose = CaptureSizeRules.isDuoOuterDisplay(capture.pixelSize) ? .closed : .open
        }
        for index in run.problems.indices where run.problems[index].target.displayType == .iPhoneDuo && run.problems[index].target.duoPose == nil {
            run.problems[index].target.duoPose = plan.duoPose(for: run.problems[index].target)
        }
        if let targets = run.primaryCaptureTargets {
            run.primaryCaptureTargets = Set(targets.map { target in
                var target = target
                if target.displayType == .iPhoneDuo, target.duoPose == nil { target.duoPose = plan.duoPose(for: target) }
                return target
            })
        }
        return run
    }
}
