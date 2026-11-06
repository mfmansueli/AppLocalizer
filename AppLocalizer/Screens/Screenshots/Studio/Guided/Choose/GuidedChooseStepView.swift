//
//  GuidedChooseStepView.swift
//  AppLocalizer
//

import SwiftUI

/// Step 5, Choose: the person's first stop. The screenshot looks, one a
/// row, and the header concepts side by side, Claude's pick marked on
/// each; Choose one of each, or ask for changes to any of them. Use These
/// (in the footer) goes on to Localize.
struct GuidedChooseStepView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    /// The width the concept cards share, measured; it starts at 0 so the
    /// cards can't lock the page wider than the sheet.
    @State private var contentWidth: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                GuidedStepTitle(title: String(localized: "Choose the look"), subtitle: subtitle)
                if run.choosesDirection {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(run.plan.makesScreenshots ? String(localized: "Screenshots") : String(localized: "App Preview"))
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(run.directions) { direction in
                            GuidedLookRow(studio: studio, run: run, direction: direction)
                        }
                    }
                }
                if run.usesConcepts {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(run.plan.alsoMakes.artworkSize.placeTitle)
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        let width = AutopilotChooseStageView.conceptWidth(in: contentWidth)
                        let pick = GuidedPick.concept(in: run)?.id
                        AutopilotDesignCardsLayout(spacing: AutopilotChooseStageView.conceptSpacing) {
                            ForEach(run.conceptsToChoose) { concept in
                                AutopilotConceptCard(
                                    studio: studio, run: run, concept: concept, isEditable: true, width: width,
                                    pickLabel: concept.id == pick ? GuidedPick.label(design: concept.source) : nil
                                )
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if let note = studio.revisionScopeNote, run.designKind.usesDesignAI {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("autopilot.guided.choose.scope")
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { contentWidth = $0 - 44 })
        .accessibilityIdentifier("autopilot.guided.choose")
    }

    /// "Claude’s pick is marked. Not quite right? Ask for changes on any
    /// of them."
    private var subtitle: String {
        let marked = String(localized: "\(GuidedPick.label(design: run.designKind)) is marked.")
        guard run.designKind.usesDesignAI else { return marked }
        return marked + " " + String(localized: "Not quite right? Ask for changes on any of them.")
    }
}
