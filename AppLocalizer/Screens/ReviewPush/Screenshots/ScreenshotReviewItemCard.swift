//
//  ScreenshotReviewItemCard.swift
//  AppLocalizer
//

import SwiftUI

/// One slot in a review group: its checkbox and name, discard ("keep
/// what's live"), and the live screenshot → the new one.
struct ScreenshotReviewItemCard: View {
    let item: ScreenshotPlanItem
    let group: ScreenshotPlanGroup
    let viewModel: ReviewPushViewModel
    let primaryLocaleName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: Spacing.xSmall) {
                Toggle(isOn: Binding(get: { viewModel.isChecked(item) }, set: { _ in viewModel.toggle(item) })) {
                    Text(item.slotTitle)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                }
                .toggleStyle(.checkbox)
                .accessibilityLabel(Text("Include \(accessibilityTitle)"))
                .accessibilityIdentifier("review.shots.check.\(Self.identifier(item))")
                Spacer(minLength: 0)
                Button {
                    viewModel.discardImage(item)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .frame(width: 16, height: 16)
                        .contentShape(Circle())
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Palette.label2)
                .background(Palette.fill1, in: Circle())
                .help(String(localized: "Keep what’s live"))
                .accessibilityLabel(Text("Discard \(accessibilityTitle)"))
                .accessibilityIdentifier("review.shots.discard.\(Self.identifier(item))")
            }
            HStack(spacing: Spacing.xxSmall) {
                let old = ScreenshotThumbnail(
                    image: viewModel.screenshots.oldImage(for: item), width: width, aspect: aspect,
                    placeholder: oldPlaceholder, isLoading: item.old != nil
                )
                if item.old != nil {
                    openButton(.live) { old }
                        .accessibilityLabel(Text("Live now"))
                } else {
                    old.accessibilityLabel(Text("Live now"))
                }
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(Palette.label3)
                    .accessibilityLabel(Text("becomes"))
                openButton(.new) {
                    ScreenshotThumbnail(
                        image: viewModel.screenshots.newImage(for: item), width: width, aspect: aspect,
                        isLoading: viewModel.screenshots.isRendering(item)
                    )
                }
                .accessibilityLabel(Text("New"))
            }
        }
        .padding(Spacing.xSmall)
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Palette.separator2, lineWidth: 0.5)
        }
        .opacity(viewModel.isChecked(item) ? 1 : 0.55)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.shots.item.\(Self.identifier(item))")
    }

    /// A thumbnail that opens the set's slots large on `side`.
    private func openButton(_ side: ReviewViewerSide, @ViewBuilder label: () -> some View) -> some View {
        Button {
            viewModel.openScreenshot(item, in: group, side: side, primaryLocaleName: primaryLocaleName)
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .help(String(localized: "Click to see it larger"))
        .accessibilityHint(Text("Shows it larger"))
        .accessibilityIdentifier("review.shots.open.\(Self.identifier(item)).\(side.rawValue)")
    }

    private var width: CGFloat { group.displayType.thumbnailWidth(phone: 34, tablet: 64) }
    private var aspect: CGFloat { ScreenshotThumbnail.aspect(of: item) }

    /// What the old side says when nothing's live in this slot.
    private var oldPlaceholder: String? {
        guard item.old == nil else { return nil }
        return group.liveSet == nil ? String(localized: "Uses \(primaryLocaleName)") : String(localized: "None")
    }

    private var accessibilityTitle: String {
        item.title(localeName: group.locale.name)
    }

    /// `ar-SA.iPhone.1`, for UI tests.
    static func identifier(_ item: ScreenshotPlanItem) -> String {
        "\(item.cell.locale).\(item.cell.displayType.shortTitle).\(item.cell.slot + 1)"
    }
}
