//
//  LanguagePageThumbnail.swift
//  AppLocalizer
//

import SwiftUI

/// One screenshot on the language page, large: its render (or, with
/// Suggested, drawn with the suggested caption and a purple ring), and
/// "Caption suggested", "Not pushed" or "Live" under it. Clicking opens the
/// full-size viewer.
struct LanguagePageThumbnail: View {
    @Bindable var viewModel: ScreenshotsViewModel
    let cell: ScreenshotCell
    let localeName: String
    let width: CGFloat

    var body: some View {
        let status = viewModel.pageStatus(of: cell)
        let preview = suggestedPreview
        VStack(spacing: Spacing.xSmall) {
            Button {
                viewModel.openViewer(cell.key)
            } label: {
                image(preview)
            }
            .buttonStyle(.plain)
            .disabled(cell.image == CellImageSource.none)
            Pill(text: status.title, style: status.isSuggested ? .machineTranslated : cell.state.isPending ? .accent : .outline)
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText(status.isSuggested)))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { viewModel.openViewer(cell.key) }
        .accessibilityIdentifier("screenshots.page.shot.\(cell.key.slot)")
    }

    /// With Suggested picked and a caption suggested: the slot drawn with it.
    private var suggestedPreview: SlotPreview? {
        guard viewModel.showsSuggestedCaptions,
              let caption = viewModel.proposedCaption(locale: cell.key.locale, slot: cell.key.slot) else { return nil }
        return viewModel.proposedPreview(for: caption, on: cell.key.displayType)
    }

    private var height: CGFloat {
        let size = viewModel.pixelSize(for: cell.key.displayType)
        return (width * CGFloat(size.height) / CGFloat(max(1, size.width))).rounded()
    }

    @ViewBuilder
    private func image(_ preview: SlotPreview?) -> some View {
        let shape = RoundedRectangle(cornerRadius: max(6, width * 0.06), style: .continuous)
        Group {
            if let preview {
                SlotPreviewImage(preview: preview, capture: viewModel.captureImage(for: preview), width: width)
            } else if let image = viewModel.thumbnail(for: cell) {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: width, height: height)
            } else {
                ZStack {
                    Palette.fill2
                    if viewModel.isRendering(cell) { ProgressView().controlSize(.small) }
                }
                .frame(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(preview == nil ? Palette.separator2 : Palette.suggestionBadge, lineWidth: preview == nil ? 0.5 : 2.5)
        }
        .contentShape(shape)
    }

    /// "Screenshot 2, German, caption suggested".
    private func accessibilityText(_ isSuggested: Bool) -> String {
        var parts = [String(localized: "Screenshot \(cell.key.slot + 1)"), localeName]
        parts.append(isSuggested ? String(localized: "caption suggested") : cell.state.title)
        return parts.joined(separator: ", ")
    }
}
