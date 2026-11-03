//
//  AutopilotPlan+DuoShots.swift
//  AppLocalizer
//

import Foundation

/// Where iPhone Duo's captures go in the screenshot document: on the
/// set's slots (one display, or both side by side, the cover one as the
/// slot's companion), or, as separate screenshots, on screens of the
/// Duo's own (inner then cover for each screen, each with its screen's
/// caption).
extension AutopilotPlan {
    /// Both displays are separate screenshots: iPhone Duo's set has
    /// screens of its own.
    var duoHasOwnScreens: Bool { plansDuo && duoScreens == .both && duoBoth == .separate }

    /// iPhone Duo's own screens, in the set's order: "Today · inner",
    /// "Today · cover"…; empty unless the displays are separate.
    var duoDeviceScreens: [DeviceScreen] {
        guard duoHasOwnScreens else { return [] }
        return duoShots.compactMap { shot in
            guard screens.indices.contains(shot.screenSlot) else { return nil }
            let name = screens[shot.screenSlot].name
            let face = shot.poses == [.closed] ? String(localized: "cover") : String(localized: "inner")
            return DeviceScreen(name: "\(name) · \(face)", captionSlot: shot.screenSlot)
        }
    }

    /// The set slots that have a screenshot of the folded phone alone (its
    /// caption is measured on that layout); a side-by-side one is laid out
    /// as the unfolded Duo's.
    var duoCoverSlots: Set<Int> {
        Set(duoShots.filter { $0.poses == [.closed] }.map(\.screenSlot))
    }

    /// The document slot a capture of set slot `slot` in `pose` goes on,
    /// and whether it's the slot's companion (the cover display beside the
    /// inner one); nil for a pose the plan doesn't use.
    func duoPlacement(slot: Int, pose: AutopilotDuoPose) -> (slot: Int, isCompanion: Bool)? {
        switch (duoScreens, duoBoth) {
        case (.inner, _): pose == .open ? (slot, false) : nil
        case (.cover, _): pose == .closed ? (slot, false) : nil
        case (.both, .sideBySide): (slot, pose == .closed)
        case (.both, .separate): duoShots.firstIndex { $0.screenSlot == slot && $0.poses == [pose] }.map { ($0, false) }
        }
    }
}
