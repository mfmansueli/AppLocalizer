//
//  AutopilotChooseStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Choose a direction: each with its five screenshots, source, language
/// checks, Open in Claude Design and Use This Direction; then Ask for
/// changes, which goes back to the design AI.
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
                }
                ForEach(run.directions) { direction in
                    AutopilotDirectionRow(
                        studio: studio, direction: direction,
                        isChosen: run.chosenDirectionID == direction.id, isEditable: isEditable,
                        stacksDevices: stacksDevices
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

    private var subtitle: String {
        run.designKind.usesDesignAI
            ? String(localized: "From \(run.designKind.title), in \(run.designName ?? run.designKind.title). Each is an AppLocalizer template you can still edit.")
            : String(localized: "AppLocalizer’s starters, in the app icon’s colors. Each is a template you can still edit.")
    }
}
