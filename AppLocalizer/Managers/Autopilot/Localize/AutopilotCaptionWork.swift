//
//  AutopilotCaptionWork.swift
//  AppLocalizer
//

import Foundation

/// The captions out to the assistant while localizing, from the run's
/// overflows: missing ones it translates (a language without them) and ones
/// too long it shortens. Missing captions are the usual work after a new
/// direction, not a problem, so the sheet says which is which.
struct AutopilotCaptionWork: Hashable, Sendable {
    var missing = 0
    var tooLong = 0
    var languages = 0

    /// Every language's, or one language's.
    init(_ overflows: [AutopilotOverflow], locale: String? = nil) {
        let out = overflows.filter { locale == nil || $0.locale == locale }
        missing = out.count { $0.headline.isEmpty }
        tooLong = out.count - missing
        languages = Set(out.map(\.locale)).count
    }

    init(missing: Int, tooLong: Int, languages: Int = 1) {
        self.missing = missing
        self.tooLong = tooLong
        self.languages = languages
    }

    var total: Int { missing + tooLong }
    var isEmpty: Bool { total == 0 }

    /// "5 captions to translate", "2 captions too long", "3 captions to
    /// translate, 2 too long".
    var summary: String {
        switch (missing, tooLong) {
        case (0, 1): String(localized: "1 caption too long")
        case let (0, long): String(localized: "\(long) captions too long")
        case (1, 0): String(localized: "1 caption to translate")
        case let (missing, 0): String(localized: "\(missing) captions to translate")
        case let (missing, long): String(localized: "\(missing) captions to translate, \(long) too long")
        }
    }

    /// A language's row: "5 captions to translate · Claude Code is writing
    /// them", or that they wait for it while nobody works on the run.
    func rowText(by client: String, isWorking: Bool) -> String {
        let who = if !isWorking {
            String(localized: "waiting for \(client)")
        } else if missing == 0 {
            String(localized: "\(client) is shortening them")
        } else if tooLong == 0 {
            String(localized: "\(client) is writing them")
        } else {
            String(localized: "\(client) is on them")
        }
        return "\(summary) · \(who)"
    }

    /// What the assistant does with them: "Claude Code is translating 65
    /// captions into 13 languages."
    func doing(by client: String) -> String {
        let into = languages == 1 ? String(localized: "1 language") : String(localized: "\(languages) languages")
        return switch (missing, tooLong) {
        case (0, _): String(localized: "\(client) is shortening \(Self.captions(tooLong)) in \(into).")
        case (_, 0): String(localized: "\(client) is translating \(Self.captions(missing)) into \(into).")
        default: String(localized: "\(client) is translating \(Self.captions(missing)) and shortening \(tooLong), in \(into).")
        }
    }

    /// "1 caption", "5 captions".
    static func captions(_ count: Int) -> String {
        count == 1 ? String(localized: "1 caption") : String(localized: "\(count) captions")
    }
}
