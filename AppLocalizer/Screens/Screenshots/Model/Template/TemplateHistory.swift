//
//  TemplateHistory.swift
//  AppLocalizer
//

import Foundation

/// Every version of an app's template, oldest first. Saving, accepting a
/// proposal and restoring all append a version; nothing is ever rewritten,
/// so a render key made from an old version keeps meaning the same thing.
struct TemplateHistory: Codable, Hashable, Sendable {
    private(set) var versions: [TemplateVersion]

    init(versions: [TemplateVersion]) {
        self.versions = versions.sorted { $0.number < $1.number }
    }

    /// A history whose first version is `template` as v1.
    static func starting(with template: ScreenshotTemplate, date: Date, author: ChangeSource = .you, note: String) -> TemplateHistory {
        var first = template
        first.version = 1
        return TemplateHistory(versions: [TemplateVersion(template: first, date: date, author: author, note: note)])
    }

    var current: TemplateVersion? { versions.last }
    var currentTemplate: ScreenshotTemplate? { current?.template }
    var currentNumber: Int { current?.number ?? 0 }

    func version(_ number: Int) -> TemplateVersion? {
        versions.first { $0.number == number }
    }

    /// The version `number` replaced: the latest one before it.
    func version(before number: Int) -> TemplateVersion? {
        versions.last { $0.number < number }
    }

    /// Saves `template` as the next version. Returns nil, and saves
    /// nothing, when it renders exactly like the current one.
    @discardableResult
    mutating func save(_ template: ScreenshotTemplate, date: Date, author: ChangeSource = .you, note: String) -> TemplateVersion? {
        if let current, current.template.contentHash == template.contentHash, current.template.name == template.name { return nil }
        return append(template, date: date, author: author, note: note, restoredFrom: nil)
    }

    /// Applies an assistant's proposal made against version `basedOn` and
    /// saves the result as a new version authored by `client`. A proposal
    /// based on an older version is refused as stale; it has to be rebased
    /// first.
    mutating func accept(
        _ operations: [TemplateOperation],
        basedOn: Int,
        from client: String,
        reason: String,
        date: Date,
        applier: TemplateOperationApplier = TemplateOperationApplier()
    ) -> Result<TemplateVersion, TemplateRefusals> {
        guard let current else {
            return .failure(TemplateRefusals(items: [TemplateRefusal(path: "", kind: .stale, reason: String(localized: "There’s no template yet."))]))
        }
        guard basedOn == current.number else {
            let reason = String(localized: "The proposal is based on v\(basedOn), but the template is at v\(current.number) now.")
            return .failure(TemplateRefusals(items: [TemplateRefusal(path: "", kind: .stale, reason: reason)]))
        }
        return applier.applying(operations, to: current.template).map { template in
            append(template, date: date, author: .assistant(client: client), note: reason, restoredFrom: nil)
        }
    }

    /// Makes a new version from an old one; the old one stays in history.
    @discardableResult
    mutating func restore(_ number: Int, date: Date, author: ChangeSource = .you) -> TemplateVersion? {
        guard let old = version(number) else { return nil }
        return append(old.template, date: date, author: author, note: String(localized: "Restored v\(number)"), restoredFrom: number)
    }

    private mutating func append(_ template: ScreenshotTemplate, date: Date, author: ChangeSource, note: String, restoredFrom: Int?) -> TemplateVersion {
        var next = template
        next.version = currentNumber + 1
        let version = TemplateVersion(template: next, date: date, author: author, note: note, restoredFrom: restoredFrom)
        versions.append(version)
        return version
    }
}
