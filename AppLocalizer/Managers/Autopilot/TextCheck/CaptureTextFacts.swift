//
//  CaptureTextFacts.swift
//  AppLocalizer
//

import Foundation

/// What AppLocalizer read in a capture: the language most of its text is
/// in, the lines cut off with an ellipsis, a line that looks like a
/// system prompt, and how much of it is blank. Kept with the capture; `AutopilotRun.textIssues(of:)`
/// says which of them are a problem.
struct CaptureTextFacts: Codable, Hashable, Sendable {
    /// "en", "de", "zh-Hans"; nil with too little text, a mix, or a
    /// language Vision can't read.
    var language: String?
    /// "Einträge durchsu…".
    var truncatedLines: [String] = []
    /// Where each of `truncatedLines` starts, from 0 at the top to 1 at
    /// the bottom; nil in captures read before it was kept.
    var truncatedTops: [Double]?
    /// Where every line ending in an ellipsis starts, cut or not: a
    /// placeholder ("Message…") or a quoted message the app shortens by
    /// design. A line cut at the same place in another language is that
    /// same element, not a translation that doesn't fit.
    var ellipsisTops: [Double]?
    /// "“Lumen” Would Like to Send You Notifications".
    var promptLine: String?
    /// The largest flat area's share of the screen, 0–1
    /// (`CaptureBlankness`); nil in captures read before it was measured.
    var blankShare: Double?

    /// How far apart two lines can start and still be the same element in
    /// two languages (Bruma's "Message…" at 0.887, "ข้อความ..." at 0.879).
    static let samePlace = 0.025

    /// The lines cut off here that aren't cut in the primary language's
    /// capture of the same screen: by where they are when both readings
    /// kept it, else by how many there are.
    func cutOffs(beyond primary: CaptureTextFacts?) -> [String] {
        if let tops = truncatedTops, tops.count == truncatedLines.count, let primaryTops = primary?.ellipsisTops {
            return zip(truncatedLines, tops)
                .filter { _, top in !primaryTops.contains { abs($0 - top) <= Self.samePlace } }
                .map(\.0)
        }
        return truncatedLines.count > (primary?.truncatedLines.count ?? 0) ? truncatedLines : []
    }
}
