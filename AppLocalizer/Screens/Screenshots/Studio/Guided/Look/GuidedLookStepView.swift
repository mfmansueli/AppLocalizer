//
//  GuidedLookStepView.swift
//  AppLocalizer
//

import SwiftUI

/// Step 2, Look: how the screenshots look (a new look, templates or the
/// current one), where the header comes from (scene templates or the
/// designer's own ideas) and what the search image shows, the App
/// Preview's music, and a note for the designer.
struct GuidedLookStepView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                GuidedStepTitle(title: String(localized: "How should it look?"), subtitle: subtitle)
                if plan.makesScreenshots {
                    screenshots
                }
                if plan.alsoMakes.makesArtwork {
                    artwork
                }
                if plan.alsoMakes.makesAppPreview, !plan.previewDisplays.isEmpty {
                    GuidedMusicRow(studio: studio, plan: plan)
                }
                GuidedDesignerNote(studio: studio, direction: plan.alsoMakes.artworkDirection)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .task { await studio.loadHeaderColors() }
    }

    private var plan: AutopilotPlan { run.plan }

    /// "Claude Design designs in Northpier Brand. You’ll choose between its
    /// proposals before anything is localized."
    private var subtitle: String {
        let designer = studio.shotStyleDesigner
        let lead = studio.shotStyleBrand.map { String(localized: "\(designer) designs in \($0).") }
            ?? String(localized: "\(designer) designs from the app’s icon and theme.")
        guard GuidedPlanTimeline.hasLookToChoose(plan) else { return lead }
        return lead + " " + String(localized: "You’ll choose between its proposals before anything is localized.")
    }

    // MARK: - Screenshots

    private var screenshots: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Screenshots").font(.headline).accessibilityAddTraits(.isHeader)
                Text(studio.guidedLiveLookText)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .accessibilityIdentifier("autopilot.guided.look.liveLook")
            }
            GuidedShotLookOptions(studio: studio, plan: plan, liveShots: studio.guidedLiveShots(count: 3))
            if plan.screenshotStyle == .templates {
                GuidedTemplateBrowser(studio: studio, plan: plan)
            }
        }
        .task { await studio.screenshots.renderStarterPreviews() }
    }

    // MARK: - Header and search

    private var artwork: some View {
        let extras = plan.alsoMakes
        let designer = studio.headerDesignerName
        return VStack(alignment: .leading, spacing: Spacing.small) {
            Text(extras.artworkSize.placeTitle).font(.headline).accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: Spacing.medium) {
                GuidedOptionCard(
                    title: String(localized: "Start from scene templates"),
                    text: String(localized: "Pick up to 3; \(designer) fits each to \(studio.app.name)"),
                    isSelected: extras.artworkStyle == .templates,
                    identifier: "autopilot.guided.look.headerStyle.templates",
                    action: { studio.setArtworkStyle(.templates) }
                )
                GuidedOptionCard(
                    title: String(localized: "Let \(designer) go freely"),
                    text: String(localized: "It studies \(studio.app.name) and proposes 3 ideas of its own"),
                    isSelected: extras.artworkStyle == .free,
                    identifier: "autopilot.guided.look.headerStyle.free",
                    action: { studio.setArtworkStyle(.free) }
                )
            }
            .fixedSize(horizontal: false, vertical: true)
            switch extras.artworkStyle {
            case .templates:
                GuidedHeaderBrowser(studio: studio, plan: plan)
            case .free:
                Text(studio.headerFreeText)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(GuidedSelectableCard())
                    .accessibilityIdentifier("autopilot.guided.look.headerFree")
            }
            HStack(spacing: 10) {
                if extras.artworkSize.searchKind == .search {
                    Text("The search image shows").font(.callout)
                    StudioSegmentedControl(
                        label: String(localized: "What the search image shows"),
                        options: AutopilotArtworkShow.allCases.map { .init(value: $0, title: $0.title, key: $0.rawValue) },
                        selection: Binding { extras.artworkShows } set: { studio.setArtworkShows($0) },
                        identifier: "autopilot.guided.look.shows"
                    )
                }
                Spacer(minLength: Spacing.small)
                Picker(String(localized: "Artwork size"), selection: Binding { extras.artworkSize } set: { studio.setArtworkSize($0) }) {
                    ForEach(AutopilotArtworkSize.allCases, id: \.self) { size in
                        Text(size.title).tag(size)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .fixedSize()
                .help(Text(ScreenshotStudioModel.artworkSizeNote))
                .accessibilityIdentifier("autopilot.guided.look.artworkSize")
            }
        }
    }
}
