//
//  ScreenshotsPushDebugData.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The design's screenshot push history: on Oct 12 at 14:32 Lumen Journal
/// pushed 80 images in its eight live locales, replacing the sets English
/// (U.S.), German and Japanese had uploaded by hand, which were kept.
enum ScreenshotsPushDebugData {
    static let backupDate = ScreenshotsSampleData.date(month: 10, day: 12, hour: 14, minute: 32)
    static let backupID = ScreenshotBackup.id(for: backupDate)
    static let recordID = UUID(uuidString: "5C2EE4C0-1012-4000-8000-000000001432") ?? UUID()
    /// The locales whose hand-uploaded sets were kept.
    static let keptLocales = ["en-US", "de-DE", "ja"]

    /// German and Japanese captions of the hand-uploaded sets.
    static let legacyCaptions: [String: [String]] = [
        "de-DE": ["Dein privates Tagebuch", "Tägliche Fragen", "Wochenrückblicke", "Fotos in jedem Eintrag", "Mit Face ID gesperrt"],
        "ja": ["あなただけの日記", "毎日の問いかけ", "週のふりかえり", "どの記録にも写真を", "Face IDでロック"],
    ]

    /// "Screenshots · 80 images in 8 locales", then "Store Page · 24 texts
    /// in 8 locales" at 14:20.
    static var records: [PushRecord] {
        var storePage = DebugReviewData.activityRecords.first { $0.title.hasPrefix("Store Page") }
        storePage?.date = ScreenshotsSampleData.date(month: 10, day: 12, hour: 14, minute: 20)
        return [screenshotRecord] + [storePage].compactMap(\.self)
    }

    static var screenshotRecord: PushRecord {
        let summary = ScreenshotPushSummary(
            pushedCount: 80, failures: [], locales: ScreenshotsSampleData.liveLocales, keptLocales: keptLocales, backupID: backupID,
            isRestore: false
        )
        return PushRecord(
            id: recordID, date: backupDate, appID: DebugFixtures.AppID.lumen, appName: "Lumen Journal", title: summary.title, pushed: [],
            screenshots: summary
        )
    }
}
#endif
