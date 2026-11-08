//
//  GuidedLookRow.swift
//  AppLocalizer
//

import SwiftUI

/// A screenshot look on Choose: its screenshots (or, without screenshots,
/// what it makes), its name with "Claude’s pick" when it's the one
/// recommended, the template pick it was made from, why it fits, Choose,
/// and Ask for Changes… for this look, written right under it.
struct GuidedLookRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let direction: AutopilotDirection
    @State private var asks = false
    @State private var note = ""

    var body: some View {
        let isChosen = run.directionToUse?.id == direction.id
        HStack(alignment: .center, spacing: 14) {
            if run.plan.makesScreenshots {
                AutopilotDirectionThumbnails(studio: studio, direction: direction, width: 62) { slot in
                    studio.openDirection(direction, at: slot)
                }
            } else {
                AutopilotDirectionExtras(studio: studio, run: run, direction: direction, fit: AutopilotDirectionExtras.Fit(height: 110))
            }
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                HStack(spacing: Spacing.xSmall) {
                    Text(direction.name).font(.callout.weight(.semibold))
                    if direction.id == GuidedPick.direction(in: run)?.id {
                        Pill(text: GuidedPick.label(design: run.designKind), style: .accent)
                            .accessibilityIdentifier("autopilot.guided.choose.look.pick")
                    }
                    // A look sent again after Ask for Changes.
                    if direction.isRevised {
                        Pill(text: RevisionLabel.title(version: 2), style: .neutral)
                            .accessibilityIdentifier("autopilot.guided.choose.look.revised")
                    }
                }
                if let origin = GuidedLookOrigin.text(for: direction, plan: run.plan, brand: studio.shotStyleBrand) {
                    Text(origin)
                        .font(.caption)
                        .foregroundStyle(Palette.label)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("autopilot.guided.choose.look.origin")
                }
                Text(direction.rationale)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                // The look's own header and search (Claude Design's pages),
                // when they aren't concepts chosen apart.
                if Self.showsOwnArtwork(run) {
                    AutopilotDirectionExtras(studio: studio, run: run, direction: direction, fit: AutopilotDirectionExtras.Fit(height: 56))
                        .padding(.vertical, 2)
                }
                if asks {
                    HStack(spacing: Spacing.xSmall) {
                        TextField(String(localized: "e.g. bigger headline, lighter background"), text: $note)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(send)
                            .accessibilityLabel(Text("Ask for changes to \(direction.name)"))
                            .accessibilityIdentifier("autopilot.guided.choose.look.note")
                        Button("Send", action: send)
                            .buttonStyle(.borderedProminent)
                            .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityIdentifier("autopilot.guided.choose.look.send")
                        Button("Cancel") {
                            asks = false
                            note = ""
                        }
                    }
                    .controlSize(.small)
                }
                HStack(spacing: Spacing.xSmall) {
                    Group {
                        if isChosen {
                            Button("Chosen") { studio.pickDirection(direction) }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button("Choose") { studio.pickDirection(direction) }
                                .buttonStyle(.bordered)
                        }
                    }
                    .accessibilityIdentifier("autopilot.guided.choose.look.use")
                    if run.designKind.usesDesignAI, !asks {
                        Button("Ask for Changes…") { asks = true }
                            .buttonStyle(.borderless)
                            .accessibilityIdentifier("autopilot.guided.choose.look.ask")
                    }
                }
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .modifier(GuidedSelectableCard(isSelected: isChosen, padding: 10))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.choose.look.\(direction.id)")
    }

    /// A look with screenshots also shows the header and search it made;
    /// without screenshots they're already its picture.
    static func showsOwnArtwork(_ run: AutopilotRun) -> Bool {
        run.plan.makesScreenshots && !run.directionArtworkKinds.isEmpty
    }

    private func send() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        asks = false
        note = ""
        studio.askForChanges(trimmed, to: direction)
    }
}
