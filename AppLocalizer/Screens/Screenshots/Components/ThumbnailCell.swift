//
//  ThumbnailCell.swift
//  AppLocalizer
//

import SwiftUI

/// One Sets cell: the render (or a spinner while it renders) with its
/// state badge underneath, a red ring when a check fails, the "UI" chip
/// and an assistant's monogram. Fallback cells are dimmed. Clicking a
/// localized cell opens the full-size viewer.
struct ThumbnailCell: View {
    let cell: ScreenshotCell
    let image: CGImage?
    let isRendering: Bool
    let width: CGFloat
    let height: CGFloat
    let localeName: String
    var onOpen: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.xxSmall) {
            Button {
                onOpen?()
            } label: {
                thumbnail
            }
            .buttonStyle(.plain)
            .disabled(onOpen == nil)
            RenderStateBadge(state: cell.state, isRendering: isRendering)
                .frame(maxWidth: width + 18)
        }
        .frame(width: width + 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
        .accessibilityAddTraits(onOpen == nil ? [] : .isButton)
        .accessibilityAction { onOpen?() }
        .accessibilityIdentifier("screenshots.cell.\(cell.key.locale).\(cell.key.slot)")
    }

    private var thumbnail: some View {
        ZStack {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else {
                Palette.fill2
                if isRendering { ProgressView().controlSize(.small) }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: Radius.flag, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.flag, style: .continuous)
                .strokeBorder(cell.state.isFailed ? Palette.dangerMark : Palette.separator, lineWidth: cell.state.isFailed ? 2 : 0.5)
        }
        .overlay(alignment: .topLeading) {
            if cell.showsPrimaryInterface, cell.state != .fallback { InterfaceChip().padding(3) }
        }
        .overlay(alignment: .topTrailing) {
            if case let .assistant(client) = cell.proposal { MonogramTag(client: client).padding(3) }
        }
        .opacity(cell.state == .fallback ? 0.4 : 1)
        .contentShape(Rectangle())
    }

    /// "German, slot 3, Overflow, UI not localized, proposal waiting".
    private var accessibilityText: String {
        var parts = [localeName, String(localized: "slot \(cell.key.slot + 1)"), isRendering ? String(localized: "Rendering") : cell.state.title]
        if cell.showsPrimaryInterface { parts.append(String(localized: "UI not localized")) }
        if cell.proposal != nil { parts.append(String(localized: "proposal waiting")) }
        return parts.joined(separator: ", ")
    }
}
