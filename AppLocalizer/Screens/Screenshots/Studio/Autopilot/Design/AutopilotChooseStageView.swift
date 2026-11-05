//
//  AutopilotChooseStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Choose a direction: each with its five screenshots (or, in a run
/// without screenshots, only what it makes), source, language checks, Open
/// in Claude Design and Use This Direction; then Ask for changes, which
/// goes back to the design AI. With header concepts, the header and search
/// are chosen apart, above the directions, and Use These goes on.
struct AutopilotChooseStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let isEditable: Bool
    /// The width the rows share, measured: it starts at 0 so the concept
    /// cards it sizes can't lock the page wider than the sheet
    /// (`AutopilotDesignCardsLayout` keeps it honest).
    @State private var contentWidth: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                if run.usesConcepts {
                    Text(Self.title(run)).font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("autopilot.choose.title")
                    conceptsSection
                    if run.hasDirections {
                        section(
                            run.plan.makesScreenshots ? String(localized: "Screenshots") : String(localized: "App Preview"),
                            subtitle: Self.directionsFrom(run), identifier: "autopilot.choose.directionsFrom",
                            titleIdentifier: "autopilot.choose.directionsTitle"
                        )
                        directionRows
                    }
                } else {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Choose a direction").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                        Spacer()
                        Text(subtitle).font(.callout).foregroundStyle(Palette.label2)
                            .accessibilityIdentifier("autopilot.choose.subtitle")
                    }
                    directionRows
                }
                if run.designKind.usesDesignAI, isEditable {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        askBar
                        if let note = studio.revisionScopeNote {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(Palette.label2)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("autopilot.choose.noteScope")
                        }
                    }
                }
            }
            .padding(Spacing.xLarge)
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { contentWidth = $0 - Spacing.xLarge * 2 })
        .accessibilityIdentifier("autopilot.choose")
    }

    private var directionRows: some View {
        ForEach(run.directions) { direction in
            AutopilotDirectionRow(
                studio: studio, direction: direction,
                isChosen: run.usesConcepts ? run.directionToUse?.id == direction.id : run.chosenDirectionID == direction.id,
                isEditable: isEditable, stacksDevices: stacksDevices, extrasFit: Self.extrasFit(run, in: contentWidth),
                choosesApart: run.usesConcepts
            )
        }
    }

    /// Header and search (or the one place the run makes): the concepts,
    /// three to a line, sharing the width the page is offered.
    private var conceptsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            section(
                run.plan.alsoMakes.artworkSize.placeTitle, subtitle: Self.conceptsFrom(run),
                identifier: "autopilot.choose.conceptsFrom", titleIdentifier: "autopilot.choose.conceptsTitle"
            )
            let width = Self.conceptWidth(in: contentWidth)
            AutopilotDesignCardsLayout(spacing: Self.conceptSpacing) {
                ForEach(run.conceptsToChoose) { concept in
                    AutopilotConceptCard(studio: studio, run: run, concept: concept, isEditable: isEditable, width: width)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func section(_ title: String, subtitle: String, identifier: String, titleIdentifier: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(title).font(.callout.weight(.semibold)).accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(titleIdentifier)
            Spacer(minLength: Spacing.small)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(identifier)
        }
    }

    static let conceptSpacing: CGFloat = 10

    /// Three concept cards share the width.
    static func conceptWidth(in width: CGFloat) -> CGFloat {
        max(((width - conceptSpacing * 2) / 3).rounded(.down), 150)
    }

    /// "Choose a direction and a header", "Choose a header".
    static func title(_ run: AutopilotRun) -> String {
        switch (run.usesConcepts, run.hasDirections) {
        case (true, true): String(localized: "Choose a direction and a header")
        case (true, false): String(localized: "Choose a header")
        default: String(localized: "Choose a direction")
        }
    }

    /// "Claude Design’s own concepts · header and search share one look ·
    /// each plays its 20-second loop"; in runs from before, "still for
    /// now: the one you choose becomes a 20-second loop" (Claude Design
    /// animates it after Use These, at Localize).
    static func conceptsFrom(_ run: AutopilotRun) -> String {
        let extras = run.plan.alsoMakes
        var line = extras.artworkStyle == .free
            ? String(localized: "\(run.designKind.title)’s own concepts")
            : String(localized: "From your templates")
        if run.plan.artworkKinds.count > 1 || run.plan.artworkKinds == [.wide] {
            line += String(localized: " · header and search share one look")
        }
        if run.animatesEachConcept {
            line += String(localized: " · each plays its \(AutopilotArtworkMotion.loopSeconds)-second loop")
        } else if extras.makesMotion {
            line += String(localized: " · still for now: the one you choose becomes a \(AutopilotArtworkMotion.loopSeconds)-second loop")
        }
        return line
    }

    /// Where the screenshot directions come from.
    static func directionsFrom(_ run: AutopilotRun) -> String {
        let source = run.designName ?? run.designKind.title
        guard run.plan.makesScreenshots else {
            return String(localized: "From \(run.designKind.title), in \(source). The App Preview’s captions and end card; the live screenshots stay as they are.")
        }
        switch run.plan.screenshotStyle {
        case .templates:
            return String(localized: "From your templates, in \(source). Each becomes an AppLocalizer template you can still edit.")
        case .keep:
            return String(localized: "Your current template, with the new captures and captions.")
        case .free:
            return String(localized: "From \(run.designKind.title), in \(source). Each is an AppLocalizer template you can still edit.")
        }
    }

    /// The note for the design source and its button.
    private var askBar: some View {
        HStack(spacing: Spacing.small) {
            TextField(String(localized: "Ask for changes, e.g. “bigger headline, lighter background”"), text: $studio.revisionNote)
                .textFieldStyle(.roundedBorder)
                .onSubmit { studio.askForChanges() }
                .accessibilityIdentifier("autopilot.choose.note")
            Button("Ask \(run.designKind.title)") { studio.askForChanges() }
                .buttonBorderShape(.capsule)
                .disabled(studio.revisionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("autopilot.choose.ask")
        }
        .padding(Spacing.small)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
    }

    /// Apple Vision Pro and Apple Watch move under the set when the row
    /// can't fit them beside it and the text.
    private var stacksDevices: Bool {
        let thumbnails = AutopilotDirectionThumbnails.oneRowWidth(
            thumbnail: 58, screens: run.plan.screens.count,
            hasVision: run.plan.displayTypes.contains(.visionPro) && !run.plan.screens(on: .visionPro).isEmpty,
            hasWatch: run.plan.displayTypes.contains(.watch) && !run.plan.screens(on: .watch).isEmpty
        )
        return Self.stacks(thumbnails: thumbnails, in: contentWidth)
    }

    /// The row's padding and spacing, the text and the thumbnails don't fit.
    static func stacks(thumbnails: CGFloat, in width: CGFloat) -> Bool {
        thumbnails + AutopilotDirectionRow.textWidth + Spacing.medium * 3 > width
    }

    /// The extras under the screenshots, 64 pt tall; without screenshots
    /// they're the whole direction: as tall as fits beside the text, up to
    /// 120 pt.
    static func extrasFit(_ run: AutopilotRun, in width: CGFloat) -> AutopilotDirectionExtras.Fit {
        let plan = run.plan
        guard !plan.makesScreenshots else { return AutopilotDirectionExtras.Fit(height: 64) }
        let room = width - AutopilotDirectionRow.textWidth - Spacing.medium * 3
        return AutopilotDirectionExtras.fit(in: room, kinds: run.directionArtworkKinds, hasPreview: !plan.previewDisplays.isEmpty, maximum: 120)
    }

    private var subtitle: String {
        guard run.designKind.usesDesignAI else {
            return run.plan.makesScreenshots
                ? String(localized: "AppLocalizer’s starters, in the app icon’s colors. Each is a template you can still edit.")
                : String(localized: "AppLocalizer’s starters, in the app icon’s colors; the live screenshots stay as they are.")
        }
        let source = run.designName ?? run.designKind.title
        if !run.plan.makesScreenshots {
            return run.plan.alsoMakes.makesArtwork
                ? String(localized: "From \(run.designKind.title), in \(source). Only the header and search images; the live screenshots stay as they are.")
                : String(localized: "From \(run.designKind.title), in \(source). Only the App Preview’s look; the live screenshots stay as they are.")
        }
        if run.directions.contains(where: { $0.artworkDesign?.isEmpty == false }) {
            return String(localized: "From \(run.designKind.title), in \(source). The screenshots are AppLocalizer templates you can still edit; the header and search images are designed by \(run.designKind.title) itself.")
        }
        return String(localized: "From \(run.designKind.title), in \(source). Each is an AppLocalizer template you can still edit.")
    }
}
