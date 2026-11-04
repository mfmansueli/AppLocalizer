//
//  AutopilotChooseStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Choose a direction: each with its five screenshots (or, in a run
/// without screenshots, only what it makes), source, language checks, Open
/// in Claude Design and Use This Direction; then Ask for changes, which
/// goes back to the design AI.
struct AutopilotChooseStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let isEditable: Bool
    /// The width the rows share.
    @State private var contentWidth: CGFloat = 900

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Choose a direction").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text(subtitle).font(.callout).foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("autopilot.choose.subtitle")
                }
                ForEach(run.directions) { direction in
                    AutopilotDirectionRow(
                        studio: studio, direction: direction,
                        isChosen: run.chosenDirectionID == direction.id, isEditable: isEditable,
                        stacksDevices: stacksDevices, extrasFit: Self.extrasFit(run.plan, in: contentWidth)
                    )
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
    static func extrasFit(_ plan: AutopilotPlan, in width: CGFloat) -> AutopilotDirectionExtras.Fit {
        guard !plan.makesScreenshots else { return AutopilotDirectionExtras.Fit(height: 64) }
        let room = width - AutopilotDirectionRow.textWidth - Spacing.medium * 3
        return AutopilotDirectionExtras.fit(in: room, kinds: plan.artworkKinds, hasPreview: !plan.previewDisplays.isEmpty, maximum: 120)
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
