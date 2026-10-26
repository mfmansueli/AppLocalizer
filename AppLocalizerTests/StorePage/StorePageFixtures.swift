//
//  StorePageFixtures.swift
//  AppLocalizerTests
//

@testable import AppLocalizer

/// A small listing for tests that need exact control over every value:
/// English (U.S.) has every field, German only its name, subtitle and
/// description.
enum StorePageFixtures {
    static let client = "Claude Code"

    static let editableVersion = ListingVersion("2.0", state: .prepareForSubmission)
    static let liveVersion = ListingVersion("1.9", state: .readyForDistribution)
    static let firstVersion = ListingVersion("1.0", state: .prepareForSubmission, isFirstVersion: true)

    static let englishTexts: [ListingField: String] = [
        .name: "Lumen: Journal",
        .subtitle: "Private notes, gentle prompts",
        .privacyPolicyURL: "https://lumen.example/privacy",
        .promotionalText: "Weekly Reflections are here.",
        .description: "Lumen keeps your notes private.\n\nUpgrade to Lumen Plus for themes and PDF export.",
        .keywords: "diary,mood,gratitude",
        .whatsNew: "Weekly Reflections and bug fixes.",
        .supportURL: "https://lumen.example/support",
        .marketingURL: "https://lumen.example",
    ]

    static let germanTexts: [ListingField: String] = [
        .name: "Lumen: Tagebuch",
        .subtitle: "Private Notizen, sanfte Fragen",
        .description: "Lumen hält deine Notizen privat.",
    ]

    static func listing(version: ListingVersion = editableVersion) -> StoreListing {
        StoreListing(appName: "Lumen Journal", version: version, primaryLocale: .englishUS, locales: [
            LocaleListing(locale: .englishUS, remote: englishTexts),
            LocaleListing(locale: .german, remote: germanTexts),
        ])
    }

    static func key(_ locale: StoreLocale, _ field: ListingField) -> ListingFieldKey {
        ListingFieldKey(locale, field)
    }
}
