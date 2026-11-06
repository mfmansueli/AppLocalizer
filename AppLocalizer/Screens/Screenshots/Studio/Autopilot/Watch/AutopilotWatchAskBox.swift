//
//  AutopilotWatchAskBox.swift
//  AppLocalizer
//

import SwiftUI

/// Ask for changes: quick asks or the person's own words go to the design
/// source, which sends a new version (v2, v3…). Only pacing, order,
/// captions and the end card change; the recordings stay.
struct AutopilotWatchAskBox: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let isEditable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                if canRevise {
                    Pill(text: "\(kind.monogram) \(kind.title)", style: .outline)
                }
                Text("Ask for changes").font(.callout.weight(.semibold))
            }
            Text("Pacing, order, captions and the end card. The recordings stay as they are; ask \(run.clientName(assistant: nil)) to record again from the plan.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            if isEditable {
                quickAsks
                HStack(spacing: Spacing.small) {
                    TextField(String(localized: "e.g. “end on the Week screen, shorter captions”"), text: $studio.previewNote)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { if canAsk { studio.askForPreviewChanges() } }
                        .disabled(!canRevise || isBusy)
                        .accessibilityLabel(Text("Ask \(kind.title) for changes"))
                        .accessibilityIdentifier("autopilot.watch.note")
                    Button(canRevise ? String(localized: "Ask \(kind.title)") : String(localized: "Needs a design project")) {
                        studio.askForPreviewChanges()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!canAsk)
                    .accessibilityIdentifier("autopilot.watch.ask")
                }
            }
            if let status {
                HStack(spacing: Spacing.small) {
                    ProgressView().controlSize(.small)
                    Text(status)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("autopilot.watch.busy")
            }
            if let revisions = review?.revisions, !revisions.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    ForEach(revisions.reversed(), id: \.version) { revision in
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                            Pill(text: "v\(revision.version)", style: .accent)
                            Text("Revised: \(revision.changes)")
                                .font(.callout)
                                .foregroundStyle(Palette.label2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("autopilot.watch.revision.\(revision.version)")
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.watch.askBox")
    }

    /// Who takes the asks: the design project's AI, or Claude in a guided
    /// run without one.
    private var kind: DesignProjectKind { run.reviser ?? run.designKind }
    private var canRevise: Bool { run.reviser != nil }
    private var review: AutopilotPreviewReview? { run.previewReview }
    private var isBusy: Bool { review?.isBusy == true }

    private var canAsk: Bool {
        canRevise && !isBusy && !studio.previewNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var quickAsks: some View {
        FlowLayout(spacing: Spacing.xSmall) {
            ForEach(ScreenshotStudioModel.previewQuickAsks, id: \.self) { ask in
                Button(ask) { studio.addPreviewAsk(ask) }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .disabled(!canRevise || isBusy)
                    .fixedSize()
                    .accessibilityIdentifier("autopilot.watch.quick.\(ask)")
            }
        }
    }

    /// Making it again, or the design source revising: "Claude Design is
    /// revising “Slower pace”. Recordings stay; only captions, pacing,
    /// order and the end card change."
    private var status: String? {
        if let remake = review?.remake { return remake.title }
        guard let request = review?.request else { return nil }
        return String(localized: "\(kind.title) is revising “\(request.note)”. Recordings stay; only captions, pacing, order and the end card change.")
    }
}
