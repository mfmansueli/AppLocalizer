//
//  CaptureIssue.swift
//  AppLocalizer
//

import Foundation

/// Why a file can't be matched on its own (design README §2 "Captures"),
/// worded as the matching row explains it.
enum CaptureIssue: Hashable, Sendable {
    /// "pt" could be Portuguese (Brazil) or Portuguese (Portugal).
    case ambiguousLocale(code: String, candidates: [StoreLocale])
    /// Not an App Store locale, or no locale in the path at all.
    case unknownLocale(code: String?)
    /// Taken on a smaller device than the set's: it would be scaled up.
    case smallerDevice(deviceName: String?, size: PixelSize, display: ScreenshotDisplayType)
    /// A slot past the template's last.
    case extraSlot(number: Int, slotCount: Int)
    /// A slot past the 10 a set can hold.
    case tooManySlots(number: Int)
    /// Neither an iPhone nor an iPad screenshot.
    case unknownDevice(size: PixelSize?)

    /// "“pt” isn’t an App Store locale.", "Taken on iPhone 16e (1170 ×
    /// 2532). The 6.9″ set needs 1320 × 2868.", "Slot 6, but the template
    /// has 5 slots."
    var message: String {
        switch self {
        case let .ambiguousLocale(code, _):
            String(localized: "“\(code)” isn’t an App Store locale.")
        case let .unknownLocale(code?):
            String(localized: "“\(code)” isn’t an App Store locale.")
        case .unknownLocale(nil):
            String(localized: "Nothing in the path names a locale.")
        case let .smallerDevice(deviceName, size, display):
            String(localized: "Taken on \(deviceName ?? display.shortTitle) (\(size.title)). The \(Self.setName(display)) set needs \(Self.neededSize(display, like: size).title).")
        case let .extraSlot(number, slotCount):
            String(localized: "Slot \(number), but the template has \(slotCount) slots.")
        case let .tooManySlots(number):
            String(localized: "Slot \(number), but a set holds at most \(ScreenshotTemplate.maximumSlots) screenshots.")
        case let .unknownDevice(size?):
            String(localized: "\(size.title) isn’t an iPhone or iPad screenshot size.")
        case .unknownDevice(nil):
            String(localized: "Not a PNG screenshot AppLocalizer can read.")
        }
    }

    /// "6.9″", "13″", "iPhone Duo".
    private static func setName(_ display: ScreenshotDisplayType) -> String {
        switch display {
        case .iPad: String(localized: "13″")
        case .iPhoneDuo: String(localized: "iPhone Duo")
        default: String(localized: "6.9″")
        }
    }

    /// The set's size in the capture's orientation.
    private static func neededSize(_ display: ScreenshotDisplayType, like size: PixelSize) -> PixelSize {
        size.isLandscape ? display.portraitPixelSize.rotated : display.portraitPixelSize
    }
}
