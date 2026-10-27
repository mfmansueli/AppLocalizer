//
//  ScreenshotReviewGroupView.swift
//  AppLocalizer
//

import SwiftUI

/// One set in review: a checkbox for the whole group, the locale and
/// display type, "Restore from Oct 12" and the assistant tag when they
/// apply, the image count, then each slot's old → new.
struct ScreenshotReviewGroupView: View {
    let group: ScreenshotPlanGroup
    let viewModel: ReviewPushViewModel
    let primaryLocaleName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            FlowLayout(spacing: 10, lineSpacing: 10) {
                ForEach(group.items) { item in
                    ScreenshotReviewItemCard(item: item, group: group, viewModel: viewModel, primaryLocaleName: primaryLocaleName)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.raised)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.shots.group.\(group.locale.code).\(group.displayType.shortTitle)")
    }

    private var header: some View {
        HStack(spacing: Spacing.small) {
            Toggle(sources: group.items.map(itemBinding), isOn: \.self) {
                EmptyView()
            }
            .toggleStyle(.checkbox)
            .labelsHidden()
            .accessibilityLabel(Text("Include \(group.locale.name) \(group.displayType.title)"))
            .accessibilityIdentifier("review.shots.groupCheck.\(group.locale.code).\(group.displayType.shortTitle)")
            FlagTile(regionCode: group.locale.regionCode)
            Text(group.locale.name)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
            Text("· \(group.displayType.title)")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
            if let date = group.restoredFrom {
                Pill(text: String(localized: "Restore from \(date.formatted(.dateTime.month(.abbreviated).day()))"))
                    .fixedSize()
            }
            if case let .assistant(client) = group.assistant {
                assistantTag(client)
            }
            Spacer(minLength: Spacing.small)
            if let previews = group.previews {
                Label(previewsTitle(previews), systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .help(String(localized: "App Previews stay as they are; pushing screenshots never uploads or deletes them."))
            }
            Text(group.countTitle)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .monospacedDigit()
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.fill1)
    }

    private func itemBinding(_ item: ScreenshotPlanItem) -> Binding<Bool> {
        Binding {
            viewModel.isChecked(item)
        } set: { isOn in
            if isOn != viewModel.isChecked(item) { viewModel.toggle(item) }
        }
    }

    /// "CC Includes Claude Code's proposals".
    private func assistantTag(_ client: String) -> some View {
        HStack(spacing: Spacing.xxSmall) {
            AssistantMonogram(letters: ChangeSource.assistant(client: client).monogram ?? "AI")
            Text("Includes \(client)’s proposals")
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.leading, 3)
        .padding(.trailing, Spacing.xSmall)
        .padding(.vertical, 2)
        .overlay(Capsule().strokeBorder(Palette.separator2, lineWidth: 1))
        .fixedSize()
        .accessibilityElement(children: .combine)
    }

    private func previewsTitle(_ previews: LiveAppPreviewSet) -> String {
        previews.previewCount == 1
            ? String(localized: "1 App Preview stays")
            : String(localized: "\(previews.previewCount) App Previews stay")
    }
}
