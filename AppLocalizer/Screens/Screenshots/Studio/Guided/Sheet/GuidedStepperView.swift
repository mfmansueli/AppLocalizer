//
//  GuidedStepperView.swift
//  AppLocalizer
//

import SwiftUI

/// The six steps across the top: done ones checked, the current one in
/// bold, the person's two marked You. While Autopilot works, the current
/// step's dot has a turning ring, and while it localizes between Choose and
/// Review & push, a light runs along the line between them.
struct GuidedStepperView: View {
    let position: Double
    /// Autopilot works on its own now (not waiting on the person).
    var isWorking = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(GuidedStep.stepper, id: \.self) { step in
                let state = step.state(at: position)
                HStack(spacing: Spacing.xSmall) {
                    dot(step, state: state)
                    Text(step.title)
                        .font(.caption.weight(state == .current ? .semibold : .regular))
                        .foregroundStyle(state == .upcoming ? Palette.label2 : Palette.label)
                        .lineLimit(1)
                        // The lines between the steps shrink, never the names.
                        .fixedSize()
                    if step.isYours {
                        Pill(text: String(localized: "You"), style: .machineTranslated)
                            .controlSize(.mini)
                            .fixedSize()
                    }
                    if step != GuidedStep.stepper.last {
                        line(after: step, state: state)
                            .frame(minWidth: 8, maxWidth: .infinity, maxHeight: 2)
                            .padding(.trailing, Spacing.small)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(label(step, state: state)))
                .accessibilityValue(Text(isWorking && state == .current ? String(localized: "running") : ""))
                .accessibilityAddTraits(state == .current ? .isSelected : [])
                .accessibilityIdentifier("autopilot.guided.step.\(step.identifier)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Steps"))
        .accessibilityIdentifier("autopilot.guided.stepper")
    }

    /// Filled once its step is done; flowing while Autopilot works past
    /// the step before it (localizing, after Choose).
    @ViewBuilder
    private func line(after step: GuidedStep, state: GuidedStepState) -> some View {
        if isWorking, state == .done, Double(step.rawValue) + 0.5 == position {
            GuidedFlowingLine()
        } else {
            Capsule().fill(state == .done ? Palette.accent : Palette.fill2)
        }
    }

    private func dot(_ step: GuidedStep, state: GuidedStepState) -> some View {
        ZStack {
            if isWorking, state == .current {
                GuidedWorkingRing(size: 28, lineWidth: 2)
            }
            Circle().fill(state == .upcoming ? Palette.fill2 : Palette.accent)
                .frame(width: 20, height: 20)
            if state == .done {
                Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
            } else {
                Text("\(step.number)").font(.system(size: 11, weight: .bold))
            }
        }
        .foregroundStyle(state == .upcoming ? Palette.label2 : Color.white)
        // The ring draws outside the dot without moving the names.
        .frame(width: 20, height: 20)
        .accessibilityHidden(true)
    }

    /// "Step 2, Look, done".
    private func label(_ step: GuidedStep, state: GuidedStepState) -> String {
        let status = switch state {
        case .done: String(localized: "done")
        case .current: String(localized: "current")
        case .upcoming: String(localized: "to come")
        }
        let yours = step.isYours ? String(localized: ", your step") : ""
        return String(localized: "Step \(step.number), \(step.title)\(yours), \(status)")
    }
}
