//
//  AutopilotMomentRow.swift
//  AppLocalizer
//

import SwiftUI

/// One moment Claude Code marked in the recording: whether it goes in the
/// App Preview, where it is and why it works, ▶ Play, and Record Again.
struct AutopilotMomentRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let moment: AutopilotRecordingMoment
    let index: Int
    let isEditable: Bool

    var body: some View {
        let name = run.plan.screen(id: moment.screenID)?.name ?? moment.screenID
        let isNow = studio.currentMomentID(run) == moment.screenID
        HStack(spacing: 10) {
            Toggle(isOn: Binding(get: { run.isChosen(moment) }, set: { studio.setMoment(moment, chosen: $0) })) {
                EmptyView()
            }
            .toggleStyle(.checkbox)
            .labelsHidden()
            .disabled(!isEditable)
            .accessibilityLabel(Text("Use \(name) in the App Preview"))
            .accessibilityIdentifier("autopilot.moment.use.\(index)")
            VStack(alignment: .leading, spacing: 1) {
                Text("\(Text("\(index + 1) · \(name)").fontWeight(.semibold)) \(Text(range).foregroundStyle(Palette.label2).monospacedDigit())")
                    .font(.callout)
                Text(moment.reason)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                if let note = studio.recordAgainNote(run, moment: moment) {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Palette.accentText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("autopilot.moment.recordAgainNote.\(index)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("▶ Play") { studio.playMoment(moment) }
                .controlSize(.small)
                .accessibilityLabel(Text("Play \(name)"))
                .accessibilityIdentifier("autopilot.moment.play.\(index)")
            Button("Record Again") { studio.recordAgain(moment) }
                .buttonStyle(.borderless)
                .font(.callout)
                .disabled(!isEditable)
                .accessibilityIdentifier("autopilot.moment.recordAgain.\(index)")
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(isNow ? Palette.fill1 : .clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.moment.\(index)")
    }

    /// "0:02–0:08".
    private var range: String {
        AutopilotRun.timeTitle(moment.start) + "–" + AutopilotRun.timeTitle(moment.end)
    }
}
