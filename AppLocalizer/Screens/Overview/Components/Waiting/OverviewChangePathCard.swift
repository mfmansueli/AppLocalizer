//
//  OverviewChangePathCard.swift
//  AppLocalizer
//

import SwiftUI

/// "How a change reaches the App Store": Suggested, then Ready to push
/// (with Review & Push… while something waits), then On the App Store.
struct OverviewChangePathCard: View {
    let suggestedCount: Int
    let readyCount: Int
    /// The version people see today, e.g. "1.3"; nil when none is live.
    let liveVersion: String?
    /// The version being edited, when it isn't the live one: "1.4".
    let editedVersion: String?
    let onReviewAndPush: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("How a change reaches the App Store")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: Spacing.small) { steps }
                VStack(alignment: .leading, spacing: Spacing.small) { steps }
            }
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("overview.changePath")
    }

    @ViewBuilder
    private var steps: some View {
        step(
            number: suggestedCount.formatted(),
            title: String(localized: "Suggested"),
            text: String(localized: "Claude Code and AppLocalizer propose. You accept or dismiss."),
            tint: suggestedCount > 0 ? Palette.suggestionBadge : nil
        )
        step(
            number: readyCount.formatted(),
            title: String(localized: "Ready to push"),
            text: String(localized: "What you accepted or edited. The App Store doesn’t change yet."),
            tint: readyCount > 0 ? Palette.accent : nil
        ) {
            if readyCount > 0 {
                Button("Review & Push…", action: onReviewAndPush)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .accessibilityIdentifier("overview.changePath.reviewAndPush")
            }
        }
        step(number: liveVersion ?? "—", title: String(localized: "On the App Store"), text: liveText, tint: nil)
    }

    private var liveText: String {
        guard let editedVersion, editedVersion != liveVersion else {
            return String(localized: "What people see today. Text and prices change when you push.")
        }
        return String(localized: "What people see today. Text and prices change when you push; \(editedVersion) after App Review.")
    }

    private func step(
        number: String, title: String, text: String, tint: Color?, @ViewBuilder action: () -> some View = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(number)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(tint ?? Palette.label)
            Text(title)
                .font(.headline)
            Text(text)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            action()
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background((tint ?? Palette.label).opacity(tint == nil ? 0.04 : 0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
