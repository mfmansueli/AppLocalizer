//
//  CaptureDropZoneView.swift
//  AppLocalizer
//

import SwiftUI

/// Before the first import (design `capt-empty`, `capt-hover`): drop a
/// folder, or start from one of the three sources, with guideline 2.3
/// explained underneath.
struct CaptureDropZoneView: View {
    @Bindable var captures: CapturesViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                dropZone
                HStack(alignment: .top, spacing: Spacing.small) {
                    CaptureSourceCard(
                        title: String(localized: "fastlane snapshot"),
                        message: String(localized: "Reads fastlane/screenshots, one folder per locale."),
                        identifier: "captures.source.fastlane"
                    ) { captures.isImporterPresented = true }
                    CaptureSourceCard(
                        title: String(localized: "Xcode test results"),
                        message: String(localized: "Attachments from an .xcresult run per language."),
                        identifier: "captures.source.xcode"
                    ) { captures.isImporterPresented = true }
                    CaptureSourceCard(
                        title: String(localized: "App Store Connect"),
                        message: String(localized: "The live screenshots. They may already have captions."),
                        identifier: "captures.source.live"
                    ) { captures.useLiveScreenshots() }
                }
                Text("App Review guideline 2.3 asks that screenshots show the app in use, so a capture must be a real screenshot. Take them in each language for the best result; a locale without its own uses \(captures.screenshots.context.primaryLocale.name) and is flagged “UI not localized”.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.large)
            }
            .frame(maxWidth: 560)
            .padding(.vertical, Spacing.xxLarge)
            .frame(maxWidth: .infinity)
        }
        .dropDestination(for: URL.self) { urls, _ in
            captures.dropHover = nil
            Task { await captures.scan(urls) }
            return !urls.isEmpty
        } isTargeted: { isTargeted in
            if isTargeted, captures.dropHover == nil { captures.dropHover = CapturesViewModel.DropHover() }
            if !isTargeted { captures.dropHover = nil }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("captures.empty")
    }

    private var isHovered: Bool { captures.dropHover != nil }

    private var title: String {
        guard let hover = captures.dropHover else { return String(localized: "Drop a folder of captures") }
        guard let count = hover.fileCount else { return String(localized: "Release to import") }
        return count == 1 ? String(localized: "Release to import 1 file") : String(localized: "Release to import \(count) files")
    }

    private var dropZone: some View {
        VStack(spacing: Spacing.small) {
            if captures.isScanning {
                ProgressView()
                    .controlSize(.regular)
                    .frame(height: 28)
            } else {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Palette.label2)
                    .frame(height: 28)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier("captures.dropTitle")
            Text("Locale folders like \(Text(verbatim: "de-DE/").monospaced()), fastlane names like \(Text(verbatim: "iPhone 17 Pro Max-03_Search.png").monospaced()), and Xcode test result attachments are matched to locale, display type and slot for you.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Choose Folder…") {
                captures.isImporterPresented = true
            }
            .padding(.top, Spacing.xxSmall)
            .accessibilityIdentifier("captures.chooseFolder")
        }
        .padding(.horizontal, Spacing.xxxLarge)
        .padding(.vertical, Spacing.xxxLarge)
        .frame(maxWidth: .infinity)
        .background(isHovered ? Palette.accentTint : Color.clear, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(isHovered ? Palette.accent : Palette.dropOutline, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("captures.dropZone")
    }
}
