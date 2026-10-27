//
//  ReviewSourceOption.swift
//  AppLocalizer
//

import Foundation

/// One segment of the "Source" filter with its count: All 170 · You 164 ·
/// Machine translation 6 · Claude Code 37. `filter` is nil for All.
struct ReviewSourceOption: Identifiable, Hashable, Sendable {
    var filter: ChangeSourceFilter?
    var count: Int

    var id: String { filter?.title ?? "all" }
    var title: String { filter?.title ?? String(localized: "All") }
}
