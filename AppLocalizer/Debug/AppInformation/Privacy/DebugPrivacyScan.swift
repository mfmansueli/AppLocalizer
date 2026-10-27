//
//  DebugPrivacyScan.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Claude Code's two scans of Lumen Journal, as the design shows them: the
/// first on Oct 26, 2026, and a later one that adds Mixpanel and suggests
/// Coarse Location. The suggestions and questions are in
/// `DebugPrivacySuggestions`.
enum DebugPrivacyScan {
    static let client = "Claude Code"

    static let firstScanDate = date(2026, 10, 26, 10, 42)
    static let secondScanDate = date(2026, 11, 9, 16, 5)

    /// "FirebaseAnalytics 11.4.0, FirebaseCrashlytics 11.4.0, GoogleAppMeasurement
    /// 11.4.0, RevenueCat 5.14.2, Sentry 8.36.0 and 9 transitive packages".
    static let sdks = [
        PrivacySDK(name: "FirebaseAnalytics", version: "11.4.0"),
        PrivacySDK(name: "FirebaseCrashlytics", version: "11.4.0"),
        PrivacySDK(name: "GoogleAppMeasurement", version: "11.4.0"),
        PrivacySDK(name: "RevenueCat", version: "5.14.2"),
        PrivacySDK(name: "Sentry", version: "8.36.0"),
        PrivacySDK(name: "FirebaseCore", version: "11.4.0"),
        PrivacySDK(name: "FirebaseCoreInternal", version: "11.4.0"),
        PrivacySDK(name: "FirebaseInstallations", version: "11.4.0"),
        PrivacySDK(name: "FirebaseSessions", version: "11.4.0"),
        PrivacySDK(name: "GoogleDataTransport", version: "10.1.0"),
        PrivacySDK(name: "GoogleUtilities", version: "8.0.2"),
        PrivacySDK(name: "nanopb", version: "3.30910.0"),
        PrivacySDK(name: "PromisesObjC", version: "2.4.0"),
        PrivacySDK(name: "swift-protobuf", version: "1.28.2"),
    ]

    static let manifests = [
        "Lumen/PrivacyInfo.xcprivacy",
        "RevenueCat 5.14.2 · PrivacyInfo.xcprivacy",
        "Sentry 8.36.0 · PrivacyInfo.xcprivacy",
        "FirebaseCrashlytics 11.4.0 · PrivacyInfo.xcprivacy",
        "GoogleAppMeasurement 11.4.0 · PrivacyInfo.xcprivacy",
        "GoogleUtilities 8.0.2 · PrivacyInfo.xcprivacy",
    ]

    /// The first scan's details, before it finished.
    static var first: PrivacyScan {
        PrivacyScan(
            assistant: client,
            repository: "northpier/lumen",
            commit: "4f2c91a",
            ranAt: firstScanDate,
            sdks: sdks,
            manifestsRead: manifests,
            trackingSignals: String(localized: "None: no NSPrivacyTracking, NSUserTrackingUsageDescription, ATTrackingManager or ASIdentifierManager."),
            couldNotSee: String(localized: "Your servers and your helpdesk: what they keep, and for how long.")
        )
    }

    /// The rescan: Mixpanel 2.10.4 was added since.
    static var second: PrivacyScan {
        var scan = first
        scan.commit = "9b03e7d"
        scan.ranAt = secondScanDate
        scan.sdks.insert(PrivacySDK(name: "Mixpanel", version: "2.10.4"), at: 3)
        scan.manifestsRead.append("Mixpanel 2.10.4 · PrivacyInfo.xcprivacy")
        return scan
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 9, _ minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? .now
    }
}
#endif
