//
//  AutopilotArtworkDirection.swift
//  AppLocalizer
//

import Foundation

/// The plan's "Expected result" for the header and search artwork: what
/// the person expects, in their words, and references they like. Sent
/// with the brief as "Your direction".
struct AutopilotArtworkDirection: Codable, Hashable, Sendable {
    var text = ""
    var references: [AutopilotArtworkReference] = []

    var isEmpty: Bool { trimmedText.isEmpty && references.isEmpty }

    var trimmedText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The quick additions under the text: ideas that fit any app (they
    /// used to name the sample app's moon and winter, on every app).
    static let additions = [
        String(localized: "Use the icon’s colors"),
        String(localized: "Bigger headline"),
        String(localized: "Hand holding the phone"),
        String(localized: "Light and airy"),
        String(localized: "Bold and high-contrast"),
    ]

    /// Adds a quick addition: on its own, or after what's there, in lower
    /// case.
    mutating func add(_ addition: String) {
        text = trimmedText.isEmpty ? addition : trimmedText + ", " + addition.lowercased()
    }

    /// "“A calm night sky over hills…” · 2 references", or the hint when
    /// there's nothing yet.
    var summary: String {
        var parts: [String] = []
        let words = trimmedText
        if !words.isEmpty { parts.append("“" + (words.count > 60 ? String(words.prefix(58)) + "…" : words) + "”") }
        if !references.isEmpty {
            parts.append(references.count == 1 ? String(localized: "1 reference") : String(localized: "\(references.count) references"))
        }
        return parts.isEmpty
            ? String(localized: "Optional: tell Claude Design what you expect, or attach images or videos you like.")
            : parts.joined(separator: " · ")
    }

    /// The brief's "Your direction" line.
    var briefLine: String {
        var line = trimmedText.isEmpty ? "" : "“" + trimmedText + "”"
        if !references.isEmpty {
            let names = references.map(\.name).joined(separator: ", ")
            line += (line.isEmpty ? "" : " ") + String(localized: "References attached: \(names). Take the feel from them; don’t copy them.")
        }
        return line
    }
}
