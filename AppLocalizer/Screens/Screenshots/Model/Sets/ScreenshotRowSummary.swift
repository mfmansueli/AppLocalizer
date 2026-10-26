//
//  ScreenshotRowSummary.swift
//  AppLocalizer
//

import Foundation

/// A row header's one-line summary: "1 check failed · 4 not pushed",
/// "UI not localized", "Live".
struct ScreenshotRowSummary: Hashable, Sendable {
    var text: String
    /// Something failed: the summary is drawn in the error color.
    var isFailing: Bool

    init(cells: [ScreenshotCell], restoredOn date: Date?) {
        var parts: [String] = []
        let failed = cells.count { $0.state.isFailed }
        if failed == 1 { parts.append(String(localized: "1 check failed")) }
        if failed > 1 { parts.append(String(localized: "\(failed) checks failed")) }
        let pending = cells.count { $0.state.isPending }
        if pending > 0 { parts.append(String(localized: "\(pending) not pushed")) }
        if let date, cells.contains(where: { $0.state == .restored }) {
            parts.append(String(localized: "Restored \(date.formatted(.dateTime.month(.abbreviated).day())) · not rendered"))
        }
        if cells.contains(where: { $0.state == .noCaption }) { parts.append(String(localized: "No captions yet")) }
        if cells.contains(where: { $0.state == .noCapture }) { parts.append(String(localized: "No captures yet")) }
        if !cells.isEmpty, cells.allSatisfy({ $0.state == .live }) { parts.append(String(localized: "Live")) }
        if cells.contains(where: { $0.state == .uploadedByHand }) { parts.append(String(localized: "Uploaded by hand · not managed")) }
        let isFallback = cells.contains { $0.state == .fallback }
        if isFallback { parts.append(String(localized: "Uses English (U.S.)")) }
        if !isFallback, cells.contains(where: \.showsPrimaryInterface) { parts.append(String(localized: "UI not localized")) }
        text = parts.isEmpty ? String(localized: "Live") : parts.joined(separator: " · ")
        isFailing = failed > 0
    }
}
