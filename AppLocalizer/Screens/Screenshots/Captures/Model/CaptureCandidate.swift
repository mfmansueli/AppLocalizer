//
//  CaptureCandidate.swift
//  AppLocalizer
//

import Foundation

/// One screenshot an import found, before it's matched: a PNG in a folder,
/// an Xcode test attachment, or a screenshot live in App Store Connect,
/// with whatever its path or set says about locale, device and slot.
struct CaptureCandidate: Hashable, Sendable, Identifiable {
    /// As the matching table shows it, e.g.
    /// `de-DE/iPhone 17 Pro Max-03_Search.png`; unique in an import.
    var path: String
    var origin: Origin
    var source: CaptureSource
    var pixelSize: PixelSize?
    /// The locale its folder, test configuration or set names, as written
    /// there ("pt", "de-DE").
    var localeCode: String?
    /// "iPhone 17 Pro Max".
    var deviceName: String?
    /// 1-based, from the name ("-03_Search") or the set's order.
    var slotNumber: Int?
    /// "Search", from the name.
    var slotName: String?
    /// Known for App Store Connect's sets; worked out from the size
    /// otherwise.
    var displayType: ScreenshotDisplayType?

    var id: String { path }

    /// Where the image comes from.
    enum Origin: Hashable, Sendable {
        case file(URL)
        case live(LiveScreenshot)
    }
}
