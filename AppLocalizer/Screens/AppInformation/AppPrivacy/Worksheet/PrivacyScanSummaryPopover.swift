//
//  PrivacyScanSummaryPopover.swift
//  AppLocalizer
//

import SwiftUI

/// Scan Summary: who scanned, where, when, the SDKs and manifests it read,
/// what it found about tracking, and what it couldn't see.
struct PrivacyScanSummaryPopover: View {
    let scan: PrivacyScan

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Scan summary")
                .font(.headline)
            Grid(alignment: .topLeading, horizontalSpacing: Spacing.medium, verticalSpacing: Spacing.xSmall) {
                row(String(localized: "Assistant"), scan.assistant)
                if let source = scan.source {
                    row(String(localized: "Repository"), source)
                }
                row(String(localized: "When"), scan.ranAt.formatted(date: .abbreviated, time: .shortened))
                if !scan.sdks.isEmpty {
                    row(String(localized: "SDKs"), sdkText)
                }
                if !scan.manifestsRead.isEmpty {
                    row(String(localized: "Manifests"), scan.manifestsRead.joined(separator: "\n"))
                }
                if let tracking = scan.trackingSignals {
                    row(String(localized: "Tracking"), tracking)
                }
                if let couldNotSee = scan.couldNotSee {
                    row(String(localized: "Couldn’t see"), couldNotSee)
                }
            }
        }
        .padding(Spacing.large)
        .frame(width: 420, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.scanSummary")
    }

    /// "FirebaseAnalytics 11.4.0, … and 9 transitive packages".
    private var sdkText: String {
        let named = scan.sdks.prefix(5).map(\.title)
        let rest = scan.sdks.count - named.count
        guard rest > 0 else { return named.formatted(.list(type: .and)) }
        return String(localized: "\(named.joined(separator: ", ")) and \(rest) transitive packages")
    }

    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(Palette.label2)
                .gridColumnAlignment(.trailing)
            Text(value)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .font(.callout)
    }
}
