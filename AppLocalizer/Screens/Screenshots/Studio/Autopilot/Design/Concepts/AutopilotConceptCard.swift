//
//  AutopilotConceptCard.swift
//  AppLocalizer
//

import SwiftUI

/// One header concept on Choose: its header above its search artwork (or
/// its one 16:9 image), its loop playing once it's animated, click to view
/// larger; its name, where it came from, metaphor, why it fits and, with
/// Motion loop, its loop's beats; Choose, and Ask for Changes… for this
/// concept only.
struct AutopilotConceptCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let concept: AutopilotArtworkConcept
    let isEditable: Bool
    /// The card's width; the header is as wide as fits, up to 250 pt.
    let width: CGFloat
    /// "Claude’s pick", on the concept the guided Choose recommends.
    var pickLabel: String?
    @State private var asks = false
    @State private var note = ""

    var body: some View {
        let isChosen = run.art == concept.id
        VStack(alignment: .leading, spacing: 6) {
            Button {
                studio.openConcept(concept, at: 0)
            } label: {
                images
            }
            .buttonStyle(.plain)
            .help(Text("Click to view larger"))
            .accessibilityLabel(Text("View \(concept.name) larger"))
            .accessibilityIdentifier("autopilot.choose.concept.zoom")
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xSmall) {
                    Text(concept.name).font(.callout.weight(.semibold))
                    if let pickLabel {
                        Pill(text: pickLabel, style: .accent)
                            .accessibilityIdentifier("autopilot.choose.concept.pick")
                    }
                }
                Text(concept.sourceTitle).font(.caption).foregroundStyle(Palette.label2)
            }
            Text(concept.metaphor)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            if !concept.fitsBecause.isEmpty {
                Text(concept.fitsBecause)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if run.plan.alsoMakes.makesMotion, let loop = concept.loopLine {
                Text(loop)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            HStack(spacing: Spacing.small) {
                Group {
                    if isChosen {
                        Button("Chosen") { studio.pickConcept(concept) }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button("Choose") { studio.pickConcept(concept) }
                            .buttonStyle(.bordered)
                    }
                }
                .disabled(!isEditable)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
                .accessibilityIdentifier("autopilot.choose.concept.use")
                if run.designKind.usesDesignAI, isEditable {
                    Button("Ask for Changes…") { asks = true }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("autopilot.choose.concept.ask")
                        .popover(isPresented: $asks, arrowEdge: .bottom) { askPopover }
                }
            }
            .buttonBorderShape(.capsule)
            .controlSize(.small)
        }
        .padding(Spacing.small)
        .frame(width: width, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                .strokeBorder(isChosen ? Color.accentColor : Palette.separator, lineWidth: isChosen ? 2 : 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.choose.concept.\(concept.id)")
    }

    /// The header with the search artwork under it, or the one 16:9 image.
    @ViewBuilder private var images: some View {
        let kinds = run.plan.artworkKinds
        let imageWidth = min(250, max(width - Spacing.small * 2, 60))
        let plays = run.playsLoop(of: concept)
        if kinds.count > 1 {
            VStack(alignment: .leading, spacing: 4) {
                AutopilotConceptThumbnail(studio: studio, run: run, concept: concept, kind: .header, width: imageWidth, plays: plays)
                HStack(alignment: .bottom, spacing: 4) {
                    AutopilotConceptThumbnail(
                        studio: studio, run: run, concept: concept, kind: .search, width: (imageWidth * 96 / 250).rounded(), plays: plays
                    )
                    Text("Header above, search results left")
                        .font(.caption2)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else if let kind = kinds.first {
            AutopilotConceptThumbnail(studio: studio, run: run, concept: concept, kind: kind, width: imageWidth, plays: plays)
        }
    }

    /// The note for this concept only.
    private var askPopover: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Ask for changes to \(concept.name)").font(.headline)
            Text("Only this concept goes back to \(run.designKind.title); the others stay as they are.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            TextField(String(localized: "e.g. “warmer sky, smaller moon”"), text: $note)
                .textFieldStyle(.roundedBorder)
                .onSubmit(send)
                .accessibilityIdentifier("autopilot.choose.concept.note")
            HStack {
                Spacer()
                Button("Cancel") { asks = false }
                    .keyboardShortcut(.cancelAction)
                Button("Ask \(run.designKind.title)", action: send)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("autopilot.choose.concept.send")
            }
        }
        .padding(Spacing.medium)
        .frame(width: 320)
    }

    private func send() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        asks = false
        note = ""
        studio.askForChanges(trimmed, to: concept)
    }
}
