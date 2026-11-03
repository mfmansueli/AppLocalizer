//
//  ScreenshotsDocument+DeviceScreens.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsDocument {
    /// The devices the set has: iPhone and iPad (the template's slots),
    /// then Apple Watch and Apple Vision Pro when they have screens.
    var displays: [ScreenshotDisplayType] {
        ScreenshotDisplayType.rendered + ScreenshotDisplayType.ownScreens.filter { !(screens(on: $0)?.isEmpty ?? true) }
    }

    /// A device's own screens; nil for iPhone and iPad, and for iPhone Duo
    /// unless its displays are separate screenshots.
    func screens(on display: ScreenshotDisplayType) -> [DeviceScreen]? {
        guard display.mayHaveOwnScreens else { return nil }
        return deviceScreens?.first { $0.displayType == display }?.screens
    }

    /// Replaces a device's own screens; empty removes them.
    mutating func setScreens(_ screens: [DeviceScreen], on display: ScreenshotDisplayType) {
        guard display.mayHaveOwnScreens else { return }
        var sets = (deviceScreens ?? []).filter { $0.displayType != display }
        if !screens.isEmpty { sets.append(DeviceScreenSet(displayType: display, screens: screens)) }
        let order = ScreenshotDisplayType.ownScreens
        sets.sort { (order.firstIndex(of: $0.displayType) ?? order.count) < (order.firstIndex(of: $1.displayType) ?? order.count) }
        deviceScreens = sets.isEmpty ? nil : sets
    }

    /// How many screenshots the device's set has.
    func slotCount(on display: ScreenshotDisplayType) -> Int {
        screens(on: display)?.count ?? (display.hasOwnScreens ? 0 : slotCount)
    }

    /// "Mood check-in" on Apple Watch, the slot's name elsewhere.
    func slotName(_ slot: Int, on display: ScreenshotDisplayType) -> String {
        guard let screens = screens(on: display) else { return slotName(slot) }
        return screens.indices.contains(slot) ? screens[slot].name : String(localized: "Screen \(slot + 1)")
    }

    /// The set slot whose caption a screenshot carries: the slot itself on
    /// iPhone and iPad, the screen's on Apple Vision Pro (and on iPhone Duo
    /// with screens of its own), none on Apple Watch.
    func captionSlot(_ slot: Int, on display: ScreenshotDisplayType) -> Int? {
        guard display.hasCaptions else { return nil }
        guard let screens = screens(on: display) else { return slot }
        return screens.indices.contains(slot) ? screens[slot].captionSlot : nil
    }
}
