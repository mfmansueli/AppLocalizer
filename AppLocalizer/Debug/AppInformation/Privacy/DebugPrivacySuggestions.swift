//
//  DebugPrivacySuggestions.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// What Claude Code suggests for Lumen Journal: twelve data types with
/// their evidence, and three open questions about what the code can't show.
enum DebugPrivacySuggestions {
    private static let client = DebugPrivacyScan.client

    /// The first scan's suggestions, in the order they arrive.
    static var first: [(PrivacyDataType, PrivacySuggestion)] {
        [
            (.userId, collected([.appFunctionality], linked: true, .high,
                                "RevenueCat identifies each purchaser with an app user ID that it keeps with their purchases.",
                                [manifest("RevenueCat", "5.14.2", .userId, linked: true, purpose: "AppFunctionality"),
                                 code("Lumen/App/LumenApp.swift", 42, "Purchases.configure(withAPIKey: Keys.revenueCat)")])),
            (.purchases, collected([.appFunctionality], linked: true, .high,
                                   "RevenueCat sends receipts to its servers and keeps purchase history per app user ID.",
                                   [manifest("RevenueCat", "5.14.2", .purchases, linked: true, purpose: "AppFunctionality"),
                                    code("Lumen/Paywall/PaywallModel.swift", 88, "try await Purchases.shared.purchase(package: package)")])),
            (.interaction, collected([.analytics], linked: false, .high,
                                     "Firebase Analytics logs events such as entry_saved and reflection_opened.",
                                     [dependency("FirebaseAnalytics", "11.4.0"),
                                      manifest("GoogleAppMeasurement", "11.4.0", .interaction, linked: false, purpose: "Analytics"),
                                      code(
                                          "Lumen/Store/EntryStore.swift",
                                          118,
                                          "Analytics.logEvent(\"entry_saved\", parameters: [\"mood\": mood.rawValue])"
                                      )])),
            (.deviceId, collected([.analytics], linked: false, .medium,
                                  "Firebase Analytics keeps an app instance ID per install. Nothing in this repo links it to a person.",
                                  [manifest("GoogleAppMeasurement", "11.4.0", .deviceId, linked: false, purpose: "Analytics")])),
            (.crash, collected([.appFunctionality], linked: false, .high,
                               "Crashlytics uploads a report when Lumen crashes.",
                               [manifest("FirebaseCrashlytics", "11.4.0", .crash, linked: false, purpose: "AppFunctionality"),
                                code("Lumen/App/AppDelegate.swift", 19, "FirebaseApp.configure()")])),
            (.performance, collected([.appFunctionality], linked: false, .medium,
                                     "Sentry traces 20% of sessions to measure launch and sync times.",
                                     [dependency("Sentry", "8.36.0"), code("Lumen/App/AppDelegate.swift", 27, "options.tracesSampleRate = 0.2")])),
            (.otherDiagnostics, collected([.appFunctionality], linked: false, .medium,
                                          "Sentry also sends breadcrumbs and device state with each event.",
                                          [manifest("Sentry", "8.36.0", .otherDiagnostics, linked: false, purpose: "AppFunctionality")])),
            (.email, collected([.appFunctionality], linked: true, .low,
                               "The Contact Support form sends the email address you reply to. Whether it’s kept depends on your helpdesk.",
                               [supportForm])),
            (.support, collected([.appFunctionality], linked: true, .low,
                                 "Support messages go to your helpdesk with the sender’s email.", [supportForm])),
            (.photos, notCollected(.high,
                                   "Photos are saved to the user’s private iCloud database, which you can’t read. That isn’t collection.",
                                   [PrivacyEvidence(kind: .infoPlist, entry: "NSPhotoLibraryUsageDescription", path: "Lumen/Info.plist", line: 31,
                                                    excerpt: "“Add photos from your library to an entry.”"),
                                    privateDatabase])),
            (.otherContent, notCollected(.medium, "Entries stay on the device and in the private iCloud database.", [privateDatabase])),
            (.health, notCollected(.high, "No HealthKit entitlement. Lumen stores a mood value, which isn’t health data.",
                                   [PrivacyEvidence(kind: .entitlement, entry: "no com.apple.developer.healthkit", path: "Lumen/Lumen.entitlements")])),
        ]
    }

    /// The rescan's new suggestion, after Mixpanel was added.
    static var coarseLocation: (PrivacyDataType, PrivacySuggestion) {
        (.coarseLocation, collected([.analytics], linked: false, .medium,
                                    "Mixpanel geolocates events from the IP address unless that’s turned off at initialization.",
                                    [PrivacyEvidence(kind: .dependency, sdk: "Mixpanel", version: "2.10.4", entry: "Package.resolved (new since Oct 26)"),
                                     code("Lumen/Analytics/Tracker.swift", 12, "Mixpanel.initialize(token: Keys.mixpanel, trackAutomaticEvents: true)")]))
    }

    static var questions: [PrivacyOpenQuestion] {
        let supportKept = PrivacyAnswer(collected: true, purposes: [.appFunctionality], linked: true)
        return [
            PrivacyOpenQuestion(
                id: "q1",
                question: String(localized: "Does your support backend keep the email address after it replies?"),
                affects: [.email, .support],
                ifYes: PrivacyQuestionEffect(summary: String(localized: "They stay collected and linked to the user."), answer: supportKept),
                ifNo: PrivacyQuestionEffect(summary: String(localized: "Both are marked not collected."), answer: .notCollected),
                client: client
            ),
            PrivacyOpenQuestion(
                id: "q2",
                question: String(localized: "Is Crashlytics linked to a user ID on your servers? This repo never calls setUserID."),
                affects: [.crash],
                ifYes: PrivacyQuestionEffect(summary: String(localized: "Crash Data becomes linked to the user."), answer: supportKept),
                ifNo: PrivacyQuestionEffect(
                    summary: String(localized: "Crash Data stays not linked."),
                    answer: PrivacyAnswer(collected: true, purposes: [.appFunctionality])
                ),
                client: client
            ),
            PrivacyOpenQuestion(
                id: "q3",
                question: String(localized: "Do Weekly Reflections send entries to a server to write the summary?"),
                affects: [.otherContent],
                ifYes: PrivacyQuestionEffect(
                    summary: String(localized: "Other User Content becomes collected, linked, for App Functionality."),
                    answer: supportKept
                ),
                ifNo: PrivacyQuestionEffect(summary: String(localized: "Other User Content stays not collected."), answer: .notCollected),
                client: client
            ),
        ]
    }

    // MARK: - Helpers

    private static func collected(
        _ purposes: Set<PrivacyPurpose>,
        linked: Bool,
        _ confidence: PrivacyConfidence,
        _ rationale: String,
        _ evidence: [PrivacyEvidence]
    ) -> PrivacySuggestion {
        PrivacySuggestion(
            answer: PrivacyAnswer(collected: true, purposes: purposes, linked: linked),
            confidence: confidence,
            rationale: rationale,
            evidence: evidence,
            client: client
        )
    }

    private static func notCollected(_ confidence: PrivacyConfidence, _ rationale: String, _ evidence: [PrivacyEvidence]) -> PrivacySuggestion {
        PrivacySuggestion(answer: .notCollected, confidence: confidence, rationale: rationale, evidence: evidence, client: client)
    }

    private static func manifest(_ sdk: String, _ version: String, _ type: PrivacyDataType, linked: Bool, purpose: String) -> PrivacyEvidence {
        PrivacyEvidence(
            kind: .sdkManifest,
            sdk: sdk,
            version: version,
            entry: type.manifestKey,
            excerpt: "Linked: \(linked) · Tracking: false · Purposes: \(purpose)"
        )
    }

    private static func dependency(_ sdk: String, _ version: String) -> PrivacyEvidence {
        PrivacyEvidence(kind: .dependency, sdk: sdk, version: version, entry: "Package.resolved")
    }

    private static func code(_ path: String, _ line: Int, _ excerpt: String) -> PrivacyEvidence {
        PrivacyEvidence(kind: .code, path: path, line: line, excerpt: excerpt)
    }

    private static let supportForm = code(
        "Lumen/Settings/SupportForm.swift",
        61,
        "request.httpBody = try encoder.encode(SupportTicket(email: email, message: text))"
    )

    private static let privateDatabase = code("Lumen/Sync/SyncEngine.swift", 58, "let db = CKContainer.default().privateCloudDatabase")
}
#endif
