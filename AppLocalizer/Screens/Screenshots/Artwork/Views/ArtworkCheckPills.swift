//
//  ArtworkCheckPills.swift
//  AppLocalizer
//

import SwiftUI

/// A header or search image's checks, shown like a screenshot's: a pill
/// per finding (red for what Apple doesn't allow there, which keeps the
/// image out of the push; yellow for advice), then the first finding's
/// line, e.g. “German header: ‘−50%’ — discounts and percentages aren’t
/// allowed here.”
struct ArtworkCheckPills: View {
    let checks: [ArtworkCheck]
    /// How many lines to say under the pills.
    var lineCount = 1

    var body: some View {
        if !checks.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    ForEach(pills, id: \.self) { pill in
                        Pill(text: pill.title, style: pill.isError ? .danger : .warning)
                    }
                }
                ForEach(Array(checks.prefix(lineCount).enumerated()), id: \.offset) { _, check in
                    Text(check.text)
                        .font(.caption)
                        .foregroundStyle(check.isError ? Palette.danger : Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if checks.count > lineCount {
                    let more = checks.count - lineCount
                    Text(more == 1 ? String(localized: "1 more finding") : String(localized: "\(more) more findings"))
                        .font(.caption)
                        .foregroundStyle(Palette.label3)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private struct PillContent: Hashable {
        var title: String
        var isError: Bool
    }

    /// One pill per reason, errors first.
    private var pills: [PillContent] {
        var seen: [PillContent] = []
        for check in checks {
            let pill = PillContent(title: check.shortReason, isError: check.isError)
            if !seen.contains(pill) { seen.append(pill) }
        }
        return seen.filter(\.isError) + seen.filter { !$0.isError }
    }
}
