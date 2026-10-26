//
//  DebugAppInformationContent+Notes.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

extension DebugAppInformationContent {
    static let assistant = "Claude Code"

    /// What Claude Code found in Lumen's project: evidence for its age
    /// rating and export compliance answers, and suggestions for Apple
    /// Watch.
    static var notes: AppInformationNotes {
        var notes = AppInformationNotes()
        notes.exportAnswers = ExportComplianceAnswers(answers: [
            .usesEncryption: true, .isExempt: true, .proprietary: false, .thirdParty: false, .availableInFrance: true,
        ])
        notes.ageEvidence = ageEvidence
        notes.exportEvidence = AssistantEvidence(
            client: assistant,
            summary: "Uses encryption: Yes · exempt: Yes · proprietary: No · third-party: No",
            why: "Lumen only uses encryption built into Apple’s operating systems.",
            evidence: [
                "Vault/EntryVault.swift:8 — import CryptoKit, AES.GCM.seal for the local entry vault",
                "All networking uses URLSession over HTTPS",
                "Package.resolved — no OpenSSL, libsodium or other crypto libraries",
            ],
            couldNotSee: "Server-side encryption isn’t part of this question. If you ship a custom VPN, messaging or DRM protocol, answer again."
        )
        notes.commonTasks = ["writing an entry", "finding one", "reading the weekly reflection", "unlocking"]
        notes.accessibilitySuggestions[DeviceFamily.appleWatch.rawValue] = [
            AccessibilitySuggestion(
                feature: .sufficientContrast,
                supports: true,
                confidence: .medium,
                rationale: "Uses system colors with Increase Contrast variants in 38 of 40 views.",
                client: assistant
            ),
            AccessibilitySuggestion(
                feature: .darkInterface,
                supports: true,
                confidence: .medium,
                rationale: "Every color comes from the asset catalog with a dark variant.",
                client: assistant
            ),
        ]
        return notes
    }

    /// Claude Code's seven age rating answers and their evidence.
    static let assistantAgeAnswers: [(AgeRatingQuestion, AgeRatingAnswer)] = [
        (.wellness, .affirmative), (.userGeneratedContent, .affirmative), (.messaging, .negative), (.webAccess, .negative),
        (.advertising, .negative), (.parentalControls, .negative), (.ageAssurance, .negative),
    ]

    private static var ageEvidence: [String: AssistantEvidence] {
        let couldNotSee = "Prompts are bundled in the app. If you later load prompts or other content from a server, answer for that content too."
        let items: [(AgeRatingQuestion, String, [String])] = [
            (.wellness, "Some prompts touch on mood, stress and sleep.", [
                "Resources/Prompts.json — 38 of 120 prompts mention mood, stress or sleep",
                "Prompts.json:211 “What helped you rest this week?”",
            ]),
            (.userGeneratedContent, "People write their own entries. They stay private and are never shown to other users.", [
                "Editor/EntryEditor.swift:44 — free-text entry editor", "No sharing or public feed found",
            ]),
            (.messaging, "No chat between people, and no open-ended chatbot.", [
                "Reflection/WeeklyReflection.swift:31 — on-device FoundationModels session summarizes the user’s own entries",
                "No messaging SDK in Package.resolved",
            ]),
            (.webAccess, "The only web view is limited to Lumen’s help pages.", [
                "Help/HelpView.swift:22 — WKWebView with a navigation delegate that blocks other hosts",
            ]),
            (.advertising, "No advertising SDKs or ad views.", ["Package.resolved — no ad networks", "No SKAdNetworkItems in Info.plist"]),
            (.parentalControls, "No parental controls in the app.", ["No Screen Time or FamilyControls entitlement"]),
            (.ageAssurance, "The app doesn’t verify ages.", ["No DeclaredAgeRange API calls found"]),
        ]
        var evidence: [String: AssistantEvidence] = [:]
        for (question, why, lines) in items {
            let answer = assistantAgeAnswers.first { $0.0 == question }?.1 ?? question.defaultAnswer
            evidence[question.rawValue] = AssistantEvidence(
                client: assistant,
                summary: "\(question.title) → \(answer.title)",
                why: why,
                evidence: lines,
                couldNotSee: couldNotSee
            )
        }
        return evidence
    }
}
#endif
