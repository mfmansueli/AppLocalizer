//
//  ExtrasReviewSection.swift
//  AppLocalizer
//

import SwiftUI

/// One app's Autopilot extras in review, under its screenshots: a card per
/// artwork kind and one for the App Previews, each language's file with its
/// checks, “Test with Product Page Optimization…” beside the header and
/// search results, and a Push button of their own (they go through the
/// App Asset Library, not with the screenshots).
struct ExtrasReviewSection: View {
    let plan: ExtrasReviewPlan
    let viewModel: ReviewPushViewModel

    private var extras: ExtrasPushController { viewModel.extras }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            heading
            ForEach(plan.artworkKinds, id: \.self) { kind in
                card(
                    title: "\(kind.title) · \(kind.ratioTitle)",
                    items: plan.items.filter { $0.artworkKind == kind },
                    placements: ProductPageTestPlacement.placements(for: kind),
                    identifier: kind.rawValue
                )
            }
            let previews = plan.items.filter { $0.artworkKind == nil }
            if !previews.isEmpty {
                card(title: String(localized: "App Previews"), items: previews, placements: [], identifier: "appPreview")
            }
            if let discarded = plan.discardedTitle {
                discardedNote(discarded)
            }
            if let run = extras.run, run.items.contains(where: { $0.appID == plan.appID }) {
                ExtrasPushProgressView(run: run)
            }
            if let error = extras.recordError {
                Text(error).font(.caption).foregroundStyle(Palette.danger).padding(.horizontal, Spacing.small)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.extras.section.\(plan.appID)")
    }

    private var heading: some View {
        HStack(spacing: Spacing.small) {
            Text(String(localized: "\(plan.appName) · Header, search and App Preview").uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.label2)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.small)
            if viewModel.screenshots.canPushExtras {
                Button("Asset Library…") { viewModel.openAssetLibrary(plan) }
                    .controlSize(.small)
                    .help(String(localized: "The files uploaded for \(plan.appName) on App Store Connect: see which are on a page and delete leftovers."))
                    .accessibilityIdentifier("review.extras.library.\(plan.appID)")
            }
            if !plan.items.isEmpty {
                Text(plan.countTitle).font(.caption).foregroundStyle(Palette.label2).monospacedDigit()
                let count = extras.checkedItems(in: plan).count
                Button(count == 1 ? String(localized: "Push 1 Extra") : String(localized: "Push \(count) Extras")) {
                    viewModel.pushExtras(plan)
                }
                .controlSize(.small)
                .disabled(count == 0 || extras.isPushing || !viewModel.screenshots.canPushExtras)
                .help(String(localized: "Uploads them to the app’s asset library and places each on its language’s page. Images with errors stay here."))
                .accessibilityIdentifier("review.extras.push.\(plan.appID)")
            }
        }
        .padding(.top, Spacing.xxSmall)
        .padding(.horizontal, Spacing.small)
    }

    private func card(title: String, items: [ExtrasReviewItem], placements: [ProductPageTestPlacement], identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.small) {
                Text(title).font(.callout.weight(.semibold))
                Spacer(minLength: Spacing.small)
                testButton(placements)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Palette.fill1)
            if items.isEmpty {
                Text(plan.discardedCount > 0
                    ? String(localized: "Nothing waiting: discarded or already on App Store Connect.")
                    : String(localized: "On App Store Connect in every language."))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
            } else {
                FlowLayout(spacing: 10, lineSpacing: 10) {
                    ForEach(items) { item in
                        ExtrasReviewTile(item: item, extras: extras) { viewModel.openExtra(item, in: plan) }
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                findings(items, identifier: identifier)
            }
        }
        .background(Palette.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.extras.card.\(identifier)")
    }

    /// "28 extras discarded: App Store Connect keeps what it has. Undo"
    private func discardedNote(_ text: String) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Text(text)
                .accessibilityIdentifier("review.extras.discarded.\(plan.appID)")
            Button("Undo") {
                Task { await viewModel.undoExtrasDiscards(plan) }
            }
            .buttonStyle(.link)
            .accessibilityIdentifier("review.extras.undo.\(plan.appID)")
        }
        .font(.caption)
        .foregroundStyle(Palette.label2)
        .padding(.horizontal, Spacing.small)
    }

    /// Each finding's line, like a screenshot check's: errors (which keep
    /// that file out of the push) first, then advice.
    @ViewBuilder
    private func findings(_ items: [ExtrasReviewItem], identifier: String) -> some View {
        let errors = items.flatMap { item in item.errors.map(\.text) + item.problems + (item.localizationID == nil ? [item.blockReason ?? ""] : []) }
        let warnings = items.flatMap { $0.warnings.map(\.text) }
        if !errors.isEmpty || !warnings.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(errors.enumerated()), id: \.offset) { _, line in
                    Label(line, systemImage: "xmark.octagon.fill")
                        .foregroundStyle(Palette.danger)
                }
                ForEach(Array(warnings.enumerated()), id: \.offset) { _, line in
                    Label(line, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(Palette.label2)
                }
            }
            .font(.caption)
            .labelStyle(.titleAndIcon)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Spacing.medium)
            .padding(.bottom, Spacing.small)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("review.extras.findings.\(identifier)")
        }
    }

    /// One placement: a button; the 16:9 image is both, so a menu.
    @ViewBuilder
    private func testButton(_ placements: [ProductPageTestPlacement]) -> some View {
        let title = String(localized: "Test with Product Page Optimization…")
        if placements.count == 1, let placement = placements.first {
            Button(title) { viewModel.openTest(plan, placement: placement) }
                .controlSize(.small)
                .accessibilityIdentifier("review.extras.test.\(placement.rawValue)")
        } else if !placements.isEmpty {
            Menu(title) {
                ForEach(placements, id: \.self) { placement in
                    Button(placement.title) { viewModel.openTest(plan, placement: placement) }
                }
            }
            .menuStyle(.button)
            .controlSize(.small)
            .fixedSize()
            .accessibilityIdentifier("review.extras.test.both")
        }
    }
}
