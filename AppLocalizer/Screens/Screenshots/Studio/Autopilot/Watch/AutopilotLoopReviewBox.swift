//
//  AutopilotLoopReviewBox.swift
//  AppLocalizer
//

import SwiftUI

/// Watch the header loop: the chosen header's header and search loops
/// playing (click to view larger, with the player's controls), what they
/// are, quick asks and the person's own words for the design source, which
/// sends a revised version, and the versions so far.
struct AutopilotLoopReviewBox: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let isEditable: Bool
    /// The width the box has, to size the loops.
    let width: CGFloat
    @State private var note = ""

    static let quickAsks = [
        String(localized: "Slower movement"), String(localized: "Warmer light"),
        String(localized: "Fewer stars"), String(localized: "Bigger name"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Text("Header and search loop").font(.callout.weight(.semibold)).accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("autopilot.loop.subtitle")
            }
            loops
            Text(String(localized: """
            Made from the header you chose. \(kind.title) animated it; AppLocalizer checked that the first and last \
            frames match and that the name never moves.
            """))
            .font(.caption)
            .foregroundStyle(Palette.label2)
            .fixedSize(horizontal: false, vertical: true)
            if let warnings = review?.motionWarnings, !warnings.isEmpty {
                Label {
                    Text("Taken after one retry: \(warnings.joined(separator: " "))")
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Palette.warning)
                }
                .font(.caption)
                .accessibilityIdentifier("autopilot.loop.warnings")
            }
            if isEditable, run.reviser != nil {
                FlowLayout(spacing: Spacing.xSmall) {
                    ForEach(Self.quickAsks, id: \.self) { ask in
                        Button(ask) { add(ask) }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                            .disabled(isBusy)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("autopilot.loop.quickAsks")
                HStack(spacing: Spacing.small) {
                    TextField(String(localized: "Ask for changes to the loop, e.g. “slower, end on the moon”"), text: $note)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(send)
                        .disabled(isBusy)
                        .accessibilityLabel(Text("Ask \(kind.title) for changes to the loop"))
                        .accessibilityIdentifier("autopilot.loop.note")
                    Button("Ask \(kind.title)", action: send)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)
                        .disabled(!canAsk)
                        .accessibilityIdentifier("autopilot.loop.ask")
                }
            }
            if let progress = AutopilotLoopProgress.make(run, now: .now) {
                // Each language takes minutes: the time left counts down
                // between them.
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    status(AutopilotLoopProgress.make(run, now: context.date) ?? progress)
                }
            }
            if let revisions = review?.revisions, !revisions.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(revisions, id: \.version) { revision in
                        Text("\(Text(RevisionLabel.title(version: revision.version)).fontWeight(.semibold)) \(Text(revision.changes.isEmpty ? revision.note : revision.changes).foregroundStyle(Palette.label2))")
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("autopilot.loop.revisions")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, Spacing.small)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.loop")
    }

    private var review: AutopilotLoopReview? { run.loopReview }
    /// Who animated it and takes the asks: the design project's AI, or
    /// Claude in a guided run without one.
    private var kind: DesignProjectKind { run.reviser ?? run.designKind }
    private var isBusy: Bool { AutopilotCenter.loopIsBusy(run) }
    private var canAsk: Bool { !isBusy && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// "Moonrise · 20 s · loops · muted", "… · muted · Revised".
    private var subtitle: String {
        let name = run.chosenConcept?.name ?? ""
        return String(localized: "\(name) · \(AutopilotArtworkMotion.loopSeconds) s · loops · muted")
            + RevisionLabel.suffix(version: review?.version)
    }

    /// The header at 470 pt with the search beside it at 200, or the one
    /// 16:9 image, smaller when the box is narrow.
    private var loops: some View {
        let kinds = run.plan.artworkKinds
        let room = width - 24
        let header: CGFloat = kinds.count > 1 ? min(470, max(200, room - 210)) : min(470, room)
        return FlowLayout(spacing: Spacing.small) {
            ForEach(Array(kinds.enumerated()), id: \.element) { index, kind in
                Button {
                    studio.openLoop(at: index)
                } label: {
                    AutopilotConceptThumbnail(
                        studio: studio, run: run, concept: run.chosenConcept, kind: kind,
                        width: kind == .search ? min(200, room) : header, plays: true
                    )
                }
                .buttonStyle(.plain)
                .help(Text("Click to view larger"))
                .accessibilityLabel(Text(kind == .search ? "View the search loop larger" : "View the header loop larger"))
                .accessibilityIdentifier("autopilot.loop.\(kind.rawValue)")
            }
        }
    }

    /// A bar with the languages and the time left while AppLocalizer makes
    /// the loop; a spinner and a sentence while the design source works.
    @ViewBuilder
    private func status(_ progress: AutopilotLoopProgress) -> some View {
        if let fraction = progress.fraction {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                    Text(progress.title).font(.callout.weight(.semibold))
                    Spacer(minLength: Spacing.small)
                    Text(progress.line)
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("autopilot.loop.busy.line")
                }
                ProgressView(value: fraction)
                    .accessibilityLabel(Text(progress.title))
                    .accessibilityValue(Text("\(Int((fraction * 100).rounded())) percent"))
                Text(progress.detail)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("autopilot.loop.busy")
        } else {
            HStack(spacing: Spacing.small) {
                ProgressView().controlSize(.small)
                Text(progress.title + " " + progress.detail)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("autopilot.loop.busy")
        }
    }

    private func add(_ ask: String) {
        note = note.isEmpty ? ask : note + ", " + ask.lowercased()
    }

    private func send() {
        guard canAsk else { return }
        studio.askForLoopChanges(note)
        note = ""
    }
}
