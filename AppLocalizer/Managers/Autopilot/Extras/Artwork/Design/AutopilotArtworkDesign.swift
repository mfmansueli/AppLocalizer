//
//  AutopilotArtworkDesign.swift
//  AppLocalizer
//

import Foundation

/// A direction's header and search artwork as Claude Design made it: one
/// self-contained HTML page per canvas, laid out at the canvas's pixel
/// size. AppLocalizer renders each page in every language
/// (`ArtworkWebRenderer`), filling in what the page marks with `data-al`
/// (the placement's text, the app's name and icon, the picked captures),
/// and animates its CSS for a motion loop. Every design decision is the
/// page's: the composition, the scene, the type and the motion.
struct AutopilotArtworkDesign: Codable, Hashable, Sendable {
    /// Each canvas's page, by `AutopilotArtworkKind` raw value.
    var pages: [String: String] = [:]
    /// Each page's own phrases (`data-al="text"`) as it writes them in the
    /// primary language, in page order, by kind raw value: what
    /// AppLocalizer translates (`ArtworkTextBook.phrases`). Nil until the
    /// pages were read (directions from before, until Localize reads them).
    var phrases: [String: [String]]?

    /// The most a page may weigh: inline SVG and data URIs count.
    static let maximumBytes = 2_000_000

    init(pages: [AutopilotArtworkKind: String] = [:]) {
        self.pages = Dictionary(uniqueKeysWithValues: pages.map { ($0.key.rawValue, $0.value) })
    }

    var isEmpty: Bool { pages.values.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }

    /// The page for `kind`, nil when there's none.
    func page(for kind: AutopilotArtworkKind) -> String? {
        guard let page = pages[kind.rawValue], !page.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return page
    }

    mutating func setPage(_ html: String?, for kind: AutopilotArtworkKind) {
        pages[kind.rawValue] = html
    }

    /// `kind`'s page's phrases; nil until it was read.
    func phrases(for kind: AutopilotArtworkKind) -> [String]? {
        phrases?[kind.rawValue]
    }

    mutating func setPhrases(_ list: [String]?, for kind: AutopilotArtworkKind) {
        var all = phrases ?? [:]
        all[kind.rawValue] = list
        phrases = all.isEmpty ? nil : all
    }

    /// Every page's phrases, each once, in `kinds`' order.
    func allPhrases(in kinds: [AutopilotArtworkKind] = AutopilotArtworkKind.allCases) -> [String] {
        var seen: Set<String> = []
        return kinds.flatMap { phrases(for: $0) ?? [] }.filter { seen.insert($0).inserted }
    }

    /// Every page has had its phrases read.
    var hasReadPhrases: Bool {
        pages.keys.allSatisfy { kind in AutopilotArtworkKind(rawValue: kind).map { page(for: $0) == nil || phrases(for: $0) != nil } ?? true }
    }

    /// The first canvas whose page writes `phrase`.
    func kind(writing phrase: String) -> AutopilotArtworkKind? {
        AutopilotArtworkKind.allCases.first { phrases(for: $0)?.contains(phrase) == true }
    }

    /// The canvases among `kinds` without a page.
    func missing(_ kinds: [AutopilotArtworkKind]) -> [AutopilotArtworkKind] {
        kinds.filter { page(for: $0) == nil }
    }

    /// These pages laid over `base`'s: a revision that sends only the
    /// search page keeps the header's.
    func laid(over base: AutopilotArtworkDesign?) -> AutopilotArtworkDesign {
        var merged = base ?? AutopilotArtworkDesign()
        for (kind, page) in pages where !page.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.pages[kind] = page
            // A new page's phrases are its own, read again when unknown.
            var all = merged.phrases ?? [:]
            all[kind] = phrases?[kind]
            merged.phrases = all.isEmpty ? nil : all
        }
        return merged
    }
}
