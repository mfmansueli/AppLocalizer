//
//  DebugEveryDevice.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Lumen Journal on every device it runs on: the standard set, plus
/// LumenWatch's four screens and three Apple Vision Pro windows (Today,
/// Week and Search) captured in every language. Live, the App Store has
/// only two English watch screenshots, uploaded by hand.
enum DebugEveryDevice {
    /// LumenWatch's screens and how Claude Code gets to each.
    static let watchScreens: [(name: String, steps: String)] = [
        ("Mood check-in", "LumenWatch → Mood"),
        ("Today’s prompt", "LumenWatch → Today"),
        ("Week", "LumenWatch → swipe to Week"),
        ("Watch face", "face “Modular” with the Lumen streak complication"),
    ]

    /// The Apple Vision Pro windows: the iPhone slot each shows, and how.
    static let visionWindows: [(slot: Int, steps: String)] = [
        (0, "window “Today” at default size"),
        (1, "window “Week”"),
        (2, "window “Search” → type “lake”"),
    ]

    /// An Apple Vision Pro window capture: the iPad layout at 2752 × 2064.
    static let visionCaptureSize = PixelSize(width: 2752, height: 2064)

    static var document: ScreenshotsDocument {
        let data = ScreenshotsSampleData.self
        var document = ScreenshotsDebugDocuments.document(for: .standard)
        document.setScreens(watchScreens.map { DeviceScreen(name: $0.name) }, on: .watch)
        document.setScreens(visionWindows.map { DeviceScreen(name: data.slotNames[$0.slot], captionSlot: $0.slot) }, on: .visionPro)
        for locale in data.scope {
            for slot in watchScreens.indices {
                document.captures.add(data.capture(locale: locale, display: .watch, slot: slot))
            }
            for slot in visionWindows.indices {
                document.captures.add(data.capture(locale: locale, display: .visionPro, slot: slot, pixelSize: visionCaptureSize))
            }
        }
        return document
    }

    /// The standard live sets and two English watch screenshots.
    static var live: LiveScreenshots {
        var live = ScreenshotsDebugDocuments.live
        let shots = (0..<2).map { slot in
            LiveScreenshot(id: "watch|en-US|\(slot)", fileName: "", checksum: "watch-en-US-\(slot)")
        }
        live.screenshotSets.append(LiveScreenshotSet(id: "set|en-US|watch", locale: "en-US", displayType: .watch, screenshots: shots))
        return live
    }

    /// The capture a live watch screenshot shows.
    static func liveWatchCapture(for id: String) -> ScreenshotCapture? {
        let parts = id.split(separator: "|")
        guard parts.count == 3, parts[0] == "watch", let slot = Int(parts[2]) else { return nil }
        return ScreenshotsSampleData.capture(locale: String(parts[1]), display: .watch, slot: slot)
    }
}
#endif
