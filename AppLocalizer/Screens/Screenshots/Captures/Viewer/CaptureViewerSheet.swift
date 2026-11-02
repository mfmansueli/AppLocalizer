//
//  CaptureViewerSheet.swift
//  AppLocalizer
//

import SwiftUI

/// A capture clicked in the Captures tab, shown large: which locale and
/// screen, its size, source and file, what its label means, and ◀ ▶ / ▲ ▼
/// (or the arrow keys) to step through the locale's screens and through
/// the locales.
struct CaptureViewerSheet: View {
    @Bindable var viewModel: ScreenshotsViewModel
    let target: CaptureViewerTarget

    private var captures: CapturesViewModel { viewModel.captures }

    var body: some View {
        let coverage = captures.coverage
        let capture = coverage?.cell(for: target)?.capture
        VStack(spacing: 0) {
            header(coverage)
            Divider()
            stage(capture, coverage: coverage)
            Divider()
            footer(coverage)
        }
        // A sheet takes its minimum width: 760 fits the 860-point window.
        .frame(minWidth: 760, idealWidth: 920, minHeight: 540, idealHeight: 780)
        .task(id: target) { load(coverage) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("captures.viewer")
    }

    /// The title and the steppers, with the size, source and file on a
    /// line of their own below.
    private func header(_ coverage: CaptureCoverage?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center, spacing: Spacing.medium) {
                Text(coverage?.viewerTitle(of: target) ?? "")
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("captures.viewer.title")
                stepper(
                    position: coverage?.screenPosition(of: target) ?? "", identifier: "screen",
                    previous: ("chevron.left", .leftArrow, String(localized: "Previous screen")),
                    next: ("chevron.right", .rightArrow, String(localized: "Next screen"))
                ) { captures.stepViewedScreen(by: $0) }
                stepper(
                    position: coverage?.localePosition(of: target) ?? "", identifier: "locale",
                    previous: ("chevron.up", .upArrow, String(localized: "Previous locale")),
                    next: ("chevron.down", .downArrow, String(localized: "Next locale"))
                ) { captures.stepViewedLocale(by: $0) }
            }
            Text(coverage?.viewerSubtitle(of: target, display: viewModel.displayType) ?? "")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .accessibilityIdentifier("captures.viewer.subtitle")
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }

    /// ◀ "Screen 2 of 5" ▶, the arrow keys doing the same.
    private func stepper(
        position: String, identifier: String,
        previous: (symbol: String, key: KeyEquivalent, label: String),
        next: (symbol: String, key: KeyEquivalent, label: String),
        step: @escaping (Int) -> Void
    ) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Button { step(-1) } label: { Image(systemName: previous.symbol) }
                .buttonBorderShape(.capsule)
                .keyboardShortcut(previous.key, modifiers: [])
                .accessibilityLabel(Text(previous.label))
                .accessibilityIdentifier("captures.viewer.\(identifier).previous")
            Text(position)
                .font(.callout.monospacedDigit())
                .foregroundStyle(Palette.label2)
                .fixedSize()
                .accessibilityIdentifier("captures.viewer.\(identifier).position")
            Button { step(1) } label: { Image(systemName: next.symbol) }
                .buttonBorderShape(.capsule)
                .keyboardShortcut(next.key, modifiers: [])
                .accessibilityLabel(Text(next.label))
                .accessibilityIdentifier("captures.viewer.\(identifier).next")
        }
    }

    private func stage(_ capture: ScreenshotCapture?, coverage: CaptureCoverage?) -> some View {
        ZStack {
            Palette.stage
            if let capture, let image = viewModel.captureImages.image(for: capture, width: CapturesViewModel.viewerPixelWidth(of: capture)) {
                Image(image, scale: 1, label: Text(coverage?.viewerTitle(of: target) ?? ""))
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                            .strokeBorder(Palette.separator, lineWidth: 0.5)
                    }
                    .padding(Spacing.xLarge)
                    .accessibilityIdentifier("captures.viewer.image")
            } else if capture != nil {
                ProgressView()
                    .accessibilityIdentifier("captures.viewer.loading")
            } else {
                Text("This capture isn’t here any more.")
                    .foregroundStyle(Palette.label2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func footer(_ coverage: CaptureCoverage?) -> some View {
        let isWrongSize = coverage?.cell(for: target)?.label == .wrongSize
        return HStack(spacing: Spacing.small) {
            if let status = coverage?.viewerStatus(of: target, display: viewModel.displayType) {
                Text(status)
                    .font(.callout)
                    .foregroundStyle(isWrongSize ? Palette.danger : Palette.label2)
                    .lineLimit(2)
                    .accessibilityIdentifier("captures.viewer.status")
            }
            Spacer()
            Button("Done") { captures.viewed = nil }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("captures.viewer.done")
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }

    /// The capture at its own width (up to 1,600 px), and the ones a step
    /// away so stepping shows them at once.
    private func load(_ coverage: CaptureCoverage?) {
        guard let coverage else { return }
        let targets = [
            target,
            coverage.target(from: target, screens: 1), coverage.target(from: target, screens: -1),
            coverage.target(from: target, locales: 1), coverage.target(from: target, locales: -1),
        ]
        var seen: Set<CaptureViewerTarget> = []
        for target in targets where seen.insert(target).inserted {
            guard let capture = coverage.cell(for: target)?.capture else { continue }
            viewModel.captureImages.request([capture], width: CapturesViewModel.viewerPixelWidth(of: capture))
        }
    }
}
