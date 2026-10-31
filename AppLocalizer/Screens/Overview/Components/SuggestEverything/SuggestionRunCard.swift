//
//  SuggestionRunCard.swift
//  AppLocalizer
//

import SwiftUI

/// Suggest Everything on Overview, in place of the assistant card once the
/// assistant announced its plan: the total and a bar, one row per page with
/// what it covers, its own count and Review, and Stop Receiving. Once it's
/// over it stays as a summary with Done and Accept All (n). When nothing
/// arrives for two minutes it says the assistant stopped sending.
struct SuggestionRunCard: View {
    let run: SuggestionRun
    /// What the run brought that's still open.
    let toReviewCount: Int
    let onReview: (SuggestionPage) -> Void
    let onStop: () -> Void
    let onDone: () -> Void
    let onAcceptAll: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 10)) { context in
            let isQuiet = run.isQuiet(at: context.date)
            Card(padding: Spacing.medium + 2) {
                header(isQuiet: isQuiet)
                if run.isRunning {
                    MeterBar(fraction: run.fraction, tint: Palette.accent)
                        .accessibilityLabel(Text("Suggestions arrived"))
                }
                rows
                footer
            }
        }
        .accessibilityIdentifier("everything.card")
    }

    private func header(isQuiet: Bool) -> some View {
        HStack(spacing: Spacing.small) {
            AssistantChip(name: run.client)
            if run.isRunning, !isQuiet {
                ProgressView()
                    .controlSize(.small)
            }
            Text(isQuiet ? run.quietText : run.title)
                .font(.headline)
            Spacer(minLength: Spacing.small)
            if !isQuiet {
                Text(run.countText)
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(Palette.label2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(run.isRunning ? .updatesFrequently : [])
        .accessibilityIdentifier("everything.card.header")
    }

    private var rows: some View {
        VStack(spacing: 0) {
            ForEach(Array(run.rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 { Divider() }
                HStack(spacing: Spacing.medium) {
                    Text(row.page.title)
                        .font(.callout.weight(.semibold))
                        .frame(width: 120, alignment: .leading)
                    Text(row.detail)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if run.isOver {
                        Text(row.countText)
                            .font(.caption)
                            .monospacedDigit()
                            .frame(width: 150, alignment: .leading)
                    } else {
                        MeterBar(fraction: row.fraction, tint: Palette.accent)
                            .frame(width: 56)
                            .accessibilityHidden(true)
                        Text(row.progressText)
                            .font(.caption)
                            .monospacedDigit()
                            .frame(width: 80, alignment: .leading)
                    }
                    Button("Review") { onReview(row.page) }
                        .controlSize(.small)
                        .disabled(row.arrived == 0)
                        .accessibilityLabel(Text("Review \(row.page.title)"))
                        .accessibilityIdentifier("everything.review.\(row.page.rawValue)")
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("everything.row.\(row.page.rawValue)")
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                .strokeBorder(Palette.separator2, lineWidth: 0.5)
        }
    }

    private var footer: some View {
        HStack(spacing: Spacing.small) {
            Text(footerText)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("everything.card.footer")
            if run.isRunning {
                Button("Stop Receiving", action: onStop)
                    .accessibilityIdentifier("everything.stop")
            } else {
                Button("Done", action: onDone)
                    .accessibilityIdentifier("everything.done")
                if toReviewCount > 0 {
                    Button("Accept All (\(toReviewCount))", action: onAcceptAll)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("everything.acceptAll")
                }
            }
        }
        .controlSize(.small)
    }

    private var footerText: String {
        switch run.phase {
        case .waiting, .running:
            return String(localized: "Review and accept while it works. Nothing is pushed until Review & Push.")
        case .stopped:
            return String(localized: "Anything \(run.client) sends now is refused. What arrived stays.")
        case .finished:
            guard toReviewCount > 0 else { return String(localized: "Everything from this run is reviewed.") }
            return toReviewCount == 1
                ? String(localized: "1 still to review. Accept All takes it; a toast offers Undo.")
                : String(localized: "\(toReviewCount) still to review. Accept All takes them all; a toast offers Undo.")
        }
    }
}
