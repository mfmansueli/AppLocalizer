//
//  GuidedDeviceChips.swift
//  AppLocalizer
//

import SwiftUI

/// The Screenshots card's devices: a chip each, on when the run makes
/// them. iPhone stays on: the picks and the design start from it.
struct GuidedDeviceChips: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan

    var body: some View {
        FlowLayout(spacing: Spacing.xxSmall) {
            ForEach(studio.planDevices(plan), id: \.self) { display in
                chip(display)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Devices"))
        .accessibilityIdentifier("autopilot.guided.make.devices")
    }

    private func chip(_ display: ScreenshotDisplayType) -> some View {
        let isOn = plan.displayTypes.contains(display)
        let isLocked = display == .iPhone
        return Button {
            studio.setPlans(display, !isOn)
        } label: {
            Text(display.shortTitle)
                .font(.callout)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, 2)
                .foregroundStyle(isOn ? Palette.accentText : Palette.label2)
                .background(isOn ? Palette.accentTint : Color.clear, in: Capsule())
                .overlay(Capsule().strokeBorder(isOn ? Palette.accent.opacity(0.5) : Palette.separator, lineWidth: 0.5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        // Not .disabled: that dims it, and iPhone looked like the one
        // device left out. The plan keeps it either way.
        .allowsHitTesting(!isLocked)
        .help(Text(studio.requiredReason(display).map { String(localized: "Required: \($0)") } ?? display.title))
        .accessibilityLabel(Text(display.title))
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityHint(isLocked ? Text("Always made") : Text(""))
        .accessibilityIdentifier("autopilot.guided.make.device.\(display == .iPad ? "iPad" : display.mcpValue)")
    }
}
