//
//  DebugScreenshotLedger.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// What a simulated App Store Connect holds for Lumen's version: its
/// screenshot sets in order, each screenshot's file and checksum, and which
/// localization each set belongs to. Starts from the sample live sets.
struct DebugScreenshotLedger: Sendable {
    struct LedgerSet: Sendable {
        var locale: String
        var displayType: ScreenshotDisplayType
        var order: [String]
    }

    struct LedgerShot: Sendable {
        var fileName: String
        var checksum: String?
        var data = Data()
        var isCommitted = true
    }

    var sets: [String: LedgerSet] = [:]
    var shots: [String: LedgerShot] = [:]
    /// Localization ID → locale code.
    var localizations: [String: String] = [:]
    var nextID = 1

    init(live: LiveScreenshots) {
        for set in live.screenshotSets {
            sets[set.id] = LedgerSet(locale: set.locale, displayType: set.displayType, order: set.screenshots.map(\.id))
            for shot in set.screenshots {
                shots[shot.id] = LedgerShot(fileName: shot.fileName, checksum: shot.checksum)
            }
        }
    }

    mutating func makeID(_ prefix: String) -> String {
        defer { nextID += 1 }
        return "debug-\(prefix)-\(nextID)"
    }

    /// The sets as the Screenshots view reads them, with `previews`.
    func live(previews: [LiveAppPreviewSet]) -> LiveScreenshots {
        let screenshotSets = sets.map { id, set in
            LiveScreenshotSet(id: id, locale: set.locale, displayType: set.displayType, screenshots: set.order.compactMap { shotID in
                shots[shotID].flatMap { $0.isCommitted ? LiveScreenshot(id: shotID, fileName: $0.fileName, checksum: $0.checksum) : nil }
            })
        }
        return LiveScreenshots(screenshotSets: screenshotSets.sorted { $0.id < $1.id }, previewSets: previews)
    }
}
#endif
