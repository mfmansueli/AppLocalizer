//
//  RenderStateBadge.swift
//  AppLocalizer
//

import SwiftUI

/// The state under a thumbnail: an icon and a word, so the state never
/// relies on color alone. Live is a quiet check, Not pushed a blue dot,
/// a failed check a red warning with its reason.
struct RenderStateBadge: View {
    let state: ScreenshotCellState
    var isRendering = false

    var body: some View {
        HStack(spacing: 3) {
            if isRendering {
                ProgressView().controlSize(.mini)
            } else {
                icon
            }
            Text(isRendering ? String(localized: "Rendering") : state.title)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(foreground)
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .background(background, in: Capsule())
        .overlay {
            if isOutlined { Capsule().strokeBorder(Palette.separator2, lineWidth: 0.5) }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .live, .uploadedByHand:
            Image(systemName: "checkmark").imageScale(.small)
        case .notPushed:
            Circle().fill(Palette.unsaved).frame(width: 6, height: 6)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").imageScale(.small)
        case .fallback:
            Image(systemName: "arrow.uturn.backward").imageScale(.small)
        case .restored:
            Image(systemName: "clock.arrow.circlepath").imageScale(.small)
        case .noCaption, .noCapture, .empty:
            EmptyView()
        }
    }

    private var foreground: Color {
        if isRendering { return Palette.label2 }
        return switch state {
        case .notPushed: Palette.accentText
        case .failed: Palette.danger
        case .noCaption, .noCapture, .fallback, .empty: Palette.label3
        default: Palette.label2
        }
    }

    private var background: Color {
        if isRendering { return .clear }
        return switch state {
        case .notPushed: Palette.accentTint
        case .failed: Palette.dangerTint
        case .restored: Palette.fill2
        default: .clear
        }
    }

    private var isOutlined: Bool {
        if isRendering { return true }
        return switch state {
        case .noCaption, .noCapture, .fallback, .empty: true
        default: false
        }
    }
}
