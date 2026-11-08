//
//  GuidedReviewStepView.swift
//  AppLocalizer
//

import SwiftUI

/// Step 6, Review & push: the person's last stop. A tab per part the run
/// made (✓ once approved), the look it has, a language and a device to
/// see it in, the part itself, and its checks with Approve. While the App
/// Preview or the header loop is still being watched, the design source
/// can change them from here; Push to App Store… (in the footer) waits
/// until every part is approved.
struct GuidedReviewStepView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    /// The width beside the checks, measured, for the screenshots and the
    /// header loop.
    @State private var width: CGFloat = 640

    private static let segmentLanguages = 4

    var body: some View {
        let parts = studio.guidedParts
        let part = studio.guidedShownPart
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                HStack(alignment: .bottom, spacing: Spacing.medium) {
                    GuidedStepTitle(
                        title: String(localized: "Review everything"),
                        subtitle: String(localized: "Approve each part, or ask for changes. Nothing reaches the App Store until you push.")
                    )
                    if parts.count > 1, let part {
                        StudioSegmentedControl(
                            label: String(localized: "Parts"),
                            options: parts.map { .init(value: $0, title: tabTitle($0), key: $0.identifier) },
                            selection: Binding { part } set: { studio.guided.reviewPart = $0 },
                            identifier: "autopilot.guided.review.tabs"
                        )
                    }
                }
                if let part {
                    HStack(alignment: .top, spacing: Spacing.large) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(lookLine(part))
                                .font(.callout.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Spacing.medium)
                                .padding(.vertical, Spacing.small)
                                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                                // The column's room, read from the look line, which
                                // always takes the width offered: the column itself
                                // would read back what the content sized from it
                                // took (the 640 it starts at, past the sheet).
                                .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { width = $0 })
                                .accessibilityIdentifier("autopilot.guided.review.look")
                            if part != .appPreview || !isWatching(.appPreview) {
                                pickers(part)
                            }
                            content(part)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        GuidedChecksCard(studio: studio, run: run, part: part)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        // A new version or music is saved with the set: read it back.
        .task(id: ReloadKey(
            stage: run.stage, version: run.previewReview?.version, music: run.plan.alsoMakes.previewMusic,
            isRemaking: run.previewReview?.remake != nil, loop: run.loopReview?.version,
            isRemakingLoop: run.loopReview?.isRemaking == true
        )) {
            await studio.screenshots.reloadDocument()
        }
        .accessibilityIdentifier("autopilot.guided.review")
    }

    private struct ReloadKey: Hashable {
        var stage: AutopilotStage
        var version: Int?
        var music: AutopilotPreviewMusic
        var isRemaking: Bool
        var loop: Int?
        var isRemakingLoop: Bool
    }

    private var plan: AutopilotPlan { run.plan }

    private func isWatching(_ part: GuidedReviewPart) -> Bool {
        GuidedReviewPart.watched(in: run).contains(part)
    }

    /// "✓ Screenshots" once approved.
    private func tabTitle(_ part: GuidedReviewPart) -> String {
        let title = part.title(plan: plan)
        return studio.isApproved(part) ? "✓ " + title : title
    }

    /// "Look: Night Ink · saved as template v5, replacing Caption above
    /// device (v4)", "Header: Day to Night · 20-second loop", "App Preview:
    /// Warm acoustic · Revised".
    private func lookLine(_ part: GuidedReviewPart) -> String {
        switch part {
        case .screenshots:
            if plan.screenshotStyle == .keep {
                return run.templateVersion.map { String(localized: "Look: your current template v\($0), with new captures and captions") }
                    ?? String(localized: "Look: your current template, with new captures and captions")
            }
            let app = studio.app.name
            let name = run.chosenDirection.map { GuidedLookName.short($0.name, app: app) } ?? String(localized: "the chosen look")
            guard let version = run.templateVersion else { return String(localized: "Look: \(name)") }
            if let replaced = studio.screenshots.document?.history?.version(before: version) {
                let before = GuidedLookName.short(replaced.template.name, app: app)
                return String(localized: "Look: \(name) · saved as template v\(version), replacing \(before) (v\(replaced.number))")
            }
            return String(localized: "Look: \(name) · saved as template v\(version)")
        case .artwork:
            let name = run.artworkName ?? String(localized: "the chosen header")
            return plan.alsoMakes.makesMotion
                ? String(localized: "\(plan.alsoMakes.artworkSize.placeTitle): \(name) · \(AutopilotArtworkMotion.loopSeconds)-second loop")
                : String(localized: "\(plan.alsoMakes.artworkSize.placeTitle): \(name)")
        case .appPreview:
            return String(localized: "App Preview: \(plan.alsoMakes.previewMusic.title)")
                + RevisionLabel.suffix(version: run.previewReview?.version)
        }
    }

    // MARK: - Language and device

    /// The language and the device side by side, or one above the other
    /// where both don't fit (six devices and four languages don't): never
    /// wider than the column, which would push the page past the sheet.
    private func pickers(_ part: GuidedReviewPart) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.small) {
                languagePicker(part)
                devicePicker(part)
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                languagePicker(part)
                devicePicker(part)
            }
        }
    }

    @ViewBuilder
    private func languagePicker(_ part: GuidedReviewPart) -> some View {
        let locales = part == .appPreview ? studio.watchLocales : plan.localeCodes
        let shown = part == .appPreview ? (studio.watchedPreview?.locale ?? plan.primaryLocale) : studio.guidedReviewLocale
        HStack(spacing: Spacing.small) {
            if locales.count > 1 {
                let segments = segmentLocales(locales)
                let titles = GuidedPreviewLocales.titles(locales)
                StudioSegmentedControl(
                    label: String(localized: "Language"),
                    options: segments.map { .init(value: $0, title: titles[$0] ?? $0, key: $0) },
                    selection: Binding { shown } set: { show(locale: $0, part: part) },
                    identifier: "autopilot.guided.review.language"
                )
                let more = locales.filter { !segments.contains($0) }
                if !more.isEmpty {
                    Menu(more.contains(shown) ? titles[shown] ?? shown : String(localized: "\(more.count) more")) {
                        ForEach(more, id: \.self) { code in
                            Button(StoreLocaleCatalog.locale(code: code)?.name ?? code) { show(locale: code, part: part) }
                        }
                    }
                    .menuStyle(.button)
                    .controlSize(.small)
                    .fixedSize()
                    .accessibilityIdentifier("autopilot.guided.review.moreLanguages")
                }
            }
        }
    }

    @ViewBuilder
    private func devicePicker(_ part: GuidedReviewPart) -> some View {
        if part == .screenshots, studio.guidedReviewDevices.count > 1 {
            StudioSegmentedControl(
                label: String(localized: "Device"),
                options: studio.guidedReviewDevices.map { .init(value: $0, title: GuidedTemplatePreviewDevices.title($0), key: $0.mcpValue) },
                selection: Binding { reviewDevice } set: { studio.guided.reviewDevice = $0 },
                identifier: "autopilot.guided.review.device"
            )
        }
        if part == .appPreview, studio.watchDevices.count > 1 {
            StudioSegmentedControl(
                label: String(localized: "Device"),
                options: studio.watchDevices.map { .init(value: $0, title: $0.shortTitle, key: $0.mcpValue) },
                selection: Binding { studio.watchedPreview?.displayType ?? studio.watchDevices[0] } set: { device in
                    studio.previewPlayer.pause()
                    studio.watchedDevice = device
                },
                identifier: "autopilot.guided.review.previewDevice"
            )
        }
    }

    /// The primary language and three that test the look (long, CJK,
    /// right to left) as segments; the rest go in the menu.
    private func segmentLocales(_ locales: [String]) -> [String] {
        Array(GuidedPreviewLocales.pick(from: locales, primary: plan.primaryLocale).prefix(Self.segmentLanguages))
    }

    private func show(locale: String, part: GuidedReviewPart) {
        if part == .appPreview {
            studio.previewPlayer.pause()
            studio.watchedLocale = locale
        } else {
            studio.guided.reviewLocale = locale
        }
    }

    private var reviewDevice: ScreenshotDisplayType {
        let devices = studio.guidedReviewDevices
        return devices.contains(studio.guided.reviewDevice) ? studio.guided.reviewDevice : devices.first ?? .iPhone
    }

    // MARK: - The part

    @ViewBuilder
    private func content(_ part: GuidedReviewPart) -> some View {
        switch part {
        case .screenshots:
            GuidedReviewShots(studio: studio, locale: studio.guidedReviewLocale, device: reviewDevice, width: width)
        case .artwork:
            // Sized from `width`, so it reports the width it's offered,
            // never its own: the row would otherwise keep offering the
            // 640 it started at.
            AutopilotDesignCardsLayout(spacing: 0) {
                if isWatching(.artwork) || (run.loopReview != nil && run.stage == .watchPreview) {
                    AutopilotLoopReviewBox(studio: studio, run: run, isEditable: run.stage == .watchPreview, width: width)
                } else {
                    GuidedReviewArtwork(studio: studio, locale: studio.guidedReviewLocale, width: width)
                }
            }
        case .appPreview:
            GuidedReviewPreview(studio: studio, run: run)
        }
    }
}
