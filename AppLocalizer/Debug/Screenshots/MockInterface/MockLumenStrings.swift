//
//  MockLumenStrings.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The sample app Lumen's interface text in one language, for the mock
/// captures DEBUG scenes draw. Sample content, not app UI, so it isn't
/// localized through the app's catalog.
struct MockLumenStrings: Hashable, Sendable {
    var date: String
    var title: String
    var promptLabel: String
    var prompt: String
    var mood: String
    var earlier: String
    var weekTitle: String
    var weekSummary: String
    var days: String
    var highlights: String
    var highlight1: String
    var highlight2: String
    var searchTitle: String
    var query: String
    var results: String
    var photoDate: String
    var photoCaption: String
    var lockTitle: String
    var lockSubtitle: String
    var unlock: String
    var moods: [String]

    static func strings(for locale: String) -> MockLumenStrings {
        table[locale] ?? table["en-US"]!
    }
}
#endif
