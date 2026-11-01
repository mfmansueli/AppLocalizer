//
//  AutopilotCapturesToCheck.swift
//  AppLocalizer
//

import SwiftUI

/// "Captures to check": the captures the set uses whose text gives
/// something away (another language, cut-off labels, a system prompt),
/// each with its language, screen and device. The assistant captured them
/// again where it could; these are the ones left.
struct AutopilotCapturesToCheck: View {
    let run: AutopilotRun
    /// Rows shown before "and N more".
    static let shownCount = 6

    var body: some View {
        let items = run.capturesToCheck
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Label(Self.title(count: items.count), systemImage: "text.magnifyingglass")
                    .font(.headline)
                Text("AppLocalizer read the text in every capture. The set uses these as they are; fix them in the app, or capture them again.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(items.prefix(Self.shownCount)) { item in
                    row(item)
                }
                if items.count > Self.shownCount {
                    Text("and \(items.count - Self.shownCount) more")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                }
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.warningMark, lineWidth: 1))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("autopilot.pick.toCheck")
        }
    }

    private func row(_ item: CaptureToCheck) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.warningMark)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(Self.place(of: item, in: run)).font(.callout.weight(.medium))
                Text(item.issues.map(\.message).joined(separator: " "))
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("autopilot.pick.toCheck.\(item.target.locale).\(item.target.screenID)")
    }

    /// "3 captures to check".
    static func title(count: Int) -> String {
        count == 1 ? String(localized: "1 capture to check") : String(localized: "\(count) captures to check")
    }

    /// "Japanese · Week · iPhone".
    static func place(of item: CaptureToCheck, in run: AutopilotRun) -> String {
        let language = StoreLocaleCatalog.locale(code: item.target.locale)?.shortName ?? item.target.locale
        let screen = run.plan.screen(id: item.target.screenID)?.name ?? item.target.screenID
        return "\(language) · \(screen) · \(item.target.displayType.shortTitle)"
    }
}
