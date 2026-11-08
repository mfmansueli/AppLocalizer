//
//  GuidedChecksCard.swift
//  AppLocalizer
//

import SwiftUI

/// Review & push's Checks, beside the part shown: what passed (✓), what
/// to look at (!), and a shortened caption to confirm with Looks Good or
/// change with Edit…; then Approve, and Edit Captions… for the
/// screenshots. What the design source can still change is asked beside
/// the part itself.
struct GuidedChecksCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let part: GuidedReviewPart

    var body: some View {
        let checks = studio.guidedChecks(for: part)
        let isApproved = studio.isApproved(part)
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Checks").font(.callout.weight(.semibold))
            ForEach(checks) { check in
                row(check)
            }
            Divider().padding(.vertical, Spacing.xxSmall)
            Group {
                if isApproved {
                    Button {
                        studio.toggleApproval(part)
                    } label: {
                        Label("Approved", systemImage: "checkmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .help(Text("Click to take the approval back"))
                } else {
                    Button {
                        studio.toggleApproval(part)
                    } label: {
                        Text(part.approveTitle(plan: run.plan)).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .buttonBorderShape(.capsule)
            .disabled(!studio.canApprove(part))
            .accessibilityAddTraits(isApproved ? .isSelected : [])
            .accessibilityIdentifier("autopilot.guided.review.approve")
            approveNote
            if part == .screenshots {
                Button("Edit Captions…") { studio.editGuidedCaptions() }
                    .buttonStyle(.link)
                    .frame(maxWidth: .infinity)
                    .help(Text("Opens the Captions tab, with every language’s captions"))
                    .accessibilityIdentifier("autopilot.guided.review.editCaptions")
            }
        }
        .font(.callout)
        .frame(width: 300, alignment: .leading)
        .modifier(GuidedSelectableCard())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.review.checks")
    }

    /// Why Approve is off and until when, while the header loop is made
    /// again.
    @ViewBuilder
    private var approveNote: some View {
        if !studio.canApprove(part), let progress = AutopilotLoopProgress.make(run, now: .now) {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text((AutopilotLoopProgress.make(run, now: context.date) ?? progress).approveNote)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("autopilot.guided.review.approveNote")
        }
    }

    private func row(_ check: GuidedCheck) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                Text(mark(check.state))
                    .fontWeight(.bold)
                    .foregroundStyle(color(check.state))
                    .frame(width: 12)
                    .accessibilityHidden(true)
                Text(check.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if check.state == .attention, !check.details.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    ForEach(check.details, id: \.self) { line in
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.leading, 18)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("autopilot.guided.review.check.\(check.id).details")
            }
            if check.state == .toConfirm {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    ForEach(check.changes, id: \.self) { change in
                        Text(change)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: Spacing.xSmall) {
                        Button("Looks Good") { studio.confirmShortenings(check) }
                            .accessibilityIdentifier("autopilot.guided.review.check.\(check.id).confirm")
                        Button("Edit…") { studio.editGuidedCaptions() }
                            .buttonStyle(.borderless)
                            .accessibilityIdentifier("autopilot.guided.review.check.\(check.id).edit")
                    }
                    .controlSize(.small)
                    .buttonBorderShape(.capsule)
                }
                .padding(.leading, 18)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(label(check.state)): \(check.text)"))
        .accessibilityIdentifier("autopilot.guided.review.check.\(check.id)")
    }

    private func mark(_ state: GuidedCheck.State) -> String {
        switch state {
        case .passed: "✓"
        case .toConfirm, .attention: "!"
        case .working: "…"
        }
    }

    private func color(_ state: GuidedCheck.State) -> Color {
        switch state {
        case .passed: Palette.decrease
        case .toConfirm: Palette.warning
        case .attention: Palette.danger
        case .working: Palette.label2
        }
    }

    private func label(_ state: GuidedCheck.State) -> String {
        switch state {
        case .passed: String(localized: "Passed")
        case .toConfirm: String(localized: "To confirm")
        case .attention: String(localized: "Needs a look")
        case .working: String(localized: "In progress")
        }
    }
}
