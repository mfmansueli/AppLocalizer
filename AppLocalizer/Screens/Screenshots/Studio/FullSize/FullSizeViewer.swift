//
//  FullSizeViewer.swift
//  AppLocalizer
//

import SwiftUI

/// The full-size viewer over the app, Quick Look–style: the item's name,
/// size and language, "2 of 5", previous and next (or the arrow keys), and
/// ✕ or Esc to close. An App Preview plays in it; Space plays or pauses
/// it, and closes the viewer on anything else.
struct FullSizeViewer: View {
    @Bindable var studio: ScreenshotStudioModel
    let viewer: StudioViewer
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            HStack(spacing: Spacing.medium) {
                Button("‹") { studio.stepViewer(-1) }
                    .buttonStyle(RoundButtonStyle())
                    .disabled(!viewer.hasPrevious)
                    .help(Text("Previous (←)"))
                    .accessibilityLabel(Text("Previous"))
                    .accessibilityIdentifier("studio.viewer.previous")
                GeometryReader { proxy in
                    FullSizeViewerContentView(studio: studio, item: viewer.current, size: proxy.size)
                        .id(viewer.current.id)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
                Button("›") { studio.stepViewer(1) }
                    .buttonStyle(RoundButtonStyle())
                    .disabled(!viewer.hasNext)
                    .help(Text("Next (→)"))
                    .accessibilityLabel(Text("Next"))
                    .accessibilityIdentifier("studio.viewer.next")
            }
            .padding(.horizontal, Spacing.large)
            .padding(.bottom, Spacing.xLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Color(red: 12 / 255, green: 12 / 255, blue: 16 / 255).opacity(0.88)
            }
            .contentShape(Rectangle())
            .onTapGesture { studio.closeViewer() }
        }
        .environment(\.colorScheme, .dark)
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onKeyPress(.leftArrow) {
            studio.stepViewer(-1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            studio.stepViewer(1)
            return .handled
        }
        .onKeyPress(.space) {
            if viewer.current.content.isAppPreview {
                studio.previewPlayer.toggle()
            } else if viewer.current.content.isRecording {
                studio.recordingPlayer.toggle()
            } else {
                studio.closeViewer()
            }
            return .handled
        }
        .onKeyPress(.escape) {
            studio.closeViewer()
            return .handled
        }
        .onExitCommand { studio.closeViewer() }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel(Text(viewer.current.title))
        .accessibilityIdentifier("studio.viewer")
    }

    private var header: some View {
        HStack(spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 1) {
                Text(viewer.current.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .accessibilityIdentifier("studio.viewer.title")
                Text(viewer.current.subtitle)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .accessibilityIdentifier("studio.viewer.subtitle")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let action = viewer.current.action {
                actionButton(action)
            }
            if let count = viewer.countTitle {
                Text(count)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.7))
                    .accessibilityIdentifier("studio.viewer.count")
            }
            Button("✕") { studio.closeViewer() }
                .buttonStyle(RoundButtonStyle())
                .help(Text("Close (Esc)"))
                .accessibilityLabel(Text("Close"))
                .accessibilityIdentifier("studio.viewer.close")
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
    }

    @ViewBuilder
    private func actionButton(_ action: StudioViewerAction) -> some View {
        let title = action.title(showsGuide: studio.viewerShowsGuide)
        if action.isProminent {
            Button(title) { studio.performViewerAction(action) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityIdentifier("studio.viewer.action")
        } else {
            Button(title) { studio.performViewerAction(action) }
                .controlSize(.small)
                .disabled(!action.isEnabled)
                .accessibilityIdentifier("studio.viewer.action")
        }
    }

    /// The viewer's round buttons: white on a light glass circle.
    private struct RoundButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) private var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.35))
                .frame(width: 34, height: 34)
                .background(Circle().fill(.white.opacity(configuration.isPressed ? 0.28 : 0.16)))
                .contentShape(Circle())
        }
    }
}
