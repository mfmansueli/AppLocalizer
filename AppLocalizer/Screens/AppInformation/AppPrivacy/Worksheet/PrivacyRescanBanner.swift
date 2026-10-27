//
//  PrivacyRescanBanner.swift
//  AppLocalizer
//

import SwiftUI

/// What a later scan changed: "Scan of Nov 9, 2026 · 16:05 · changes since
/// Oct 26, 2026", then SDKs added or removed, new or different suggestions,
/// and how many answers stayed the same.
struct PrivacyRescanBanner: View {
    let scan: PrivacyScan
    let changes: PrivacyScanChanges
    let worksheet: PrivacyWorksheet

    var body: some View {
        PrivacyNotice {
            Text(title)
                .fontWeight(.semibold)
            ForEach(changes.addedSDKs, id: \.self) { sdk in
                line("+", String(localized: "\(sdk.title) added to Package.resolved"))
            }
            ForEach(changes.removedSDKs, id: \.self) { sdk in
                line("−", String(localized: "\(sdk.title) removed"))
            }
            ForEach(changes.changedTypes, id: \.self) { type in
                line("+", suggestionLine(type))
            }
            line("=", String(localized: "\(changes.unchangedCount) answers unchanged"))
        }
        .accessibilityIdentifier("appInformation.appPrivacy.rescan")
    }

    private var title: String {
        let when = scan.ranAt.formatted(date: .abbreviated, time: .shortened)
        let since = changes.since.formatted(date: .abbreviated, time: .omitted)
        return String(localized: "Scan of \(when) · changes since \(since)")
    }

    /// "Coarse Location suggested as collected, for Analytics".
    private func suggestionLine(_ type: PrivacyDataType) -> String {
        guard let answer = worksheet[type]?.conflict?.answer ?? worksheet[type]?.suggestion?.answer else {
            return String(localized: "\(type.name) changed")
        }
        guard answer.collected else { return String(localized: "\(type.name) suggested as not collected") }
        let purposes = answer.sortedPurposes.map(\.title).formatted(.list(type: .and))
        return String(localized: "\(type.name) suggested as collected, for \(purposes)")
    }

    private func line(_ mark: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(mark)
                .monospaced()
                .foregroundStyle(Palette.label2)
                .accessibilityHidden(true)
            Text(text)
        }
        .font(.callout)
    }
}
