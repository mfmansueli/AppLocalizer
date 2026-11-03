//
//  AppPreviewCut.swift
//  AppLocalizer
//

import Foundation

/// How an App Preview is cut from its recordings, the part the design
/// source can revise when the person asks for changes: which screens play
/// and in what order, how long it runs, how big the captions are, and what
/// the end card says. The recordings stay as they are. Everything unset
/// is AppLocalizer's: the plan's screens in order, 24 seconds, the
/// template's caption size, the first screen's caption on the end card.
struct AppPreviewCut: Codable, Hashable, Sendable {
    /// The screens that play, in order; nil plays every screen in the
    /// plan's order.
    var screenIDs: [String]?
    /// 15–30 seconds; nil is 24.
    var seconds: Double?
    /// 0.8–1.4 times the template's caption size; nil is 1.
    var captionScale: Double?
    /// The screen whose caption the end card shows; nil is the first that
    /// plays.
    var endCardScreenID: String?
    /// False shows only the app's name on the end card.
    var endCardShowsCaption: Bool?

    static let secondsRange = 15.0...30.0
    static let captionScaleRange = 0.8...1.4

    /// Apple's 15–30 seconds; 24 by default.
    var targetSeconds: Double {
        min(max(seconds ?? Double(AutopilotExtras.previewSeconds), Self.secondsRange.lowerBound), Self.secondsRange.upperBound)
    }

    var captionScaleValue: Double {
        min(max(captionScale ?? 1, Self.captionScaleRange.lowerBound), Self.captionScaleRange.upperBound)
    }

    var showsEndCardCaption: Bool { endCardShowsCaption ?? true }

    /// `ids` (the plan's order) as this cut plays them: its own order,
    /// leaving out what it leaves out and what the plan doesn't have.
    func order(_ ids: [String]) -> [String] {
        guard let screenIDs, !screenIDs.isEmpty else { return ids }
        var seen: Set<String> = []
        let ordered = screenIDs.filter { ids.contains($0) && seen.insert($0).inserted }
        return ordered.isEmpty ? ids : ordered
    }

    /// The default cut.
    var isStandard: Bool { self == AppPreviewCut() }
}
