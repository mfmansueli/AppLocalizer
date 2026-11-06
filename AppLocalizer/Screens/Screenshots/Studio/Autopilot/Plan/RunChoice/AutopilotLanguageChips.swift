//
//  AutopilotLanguageChips.swift
//  AppLocalizer
//

import SwiftUI

/// Choose…: a chip per language, on when the run has it. The primary
/// language stays on: picks and the design start from it.
struct AutopilotLanguageChips: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan

    var body: some View {
        FlowLayout(spacing: Spacing.xSmall) {
            ForEach(plan.availableLocaleCodes, id: \.self) { code in
                chip(code)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.languageChips")
    }

    private func chip(_ code: String) -> some View {
        let isOn = plan.localeCodes.contains(code)
        let isPrimary = code == plan.primaryLocale
        let name = StoreLocaleCatalog.locale(code: code)?.shortName ?? code
        let isNew = plan.newLocaleCodes?.contains(code) == true
        return Button {
            studio.setChooses(code, !isOn)
        } label: {
            Text(isNew ? String(localized: "\(name) · new") : name)
                .font(.callout)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, 2)
                .foregroundStyle(isOn ? Color.accentColor : Palette.label2)
                .background(isOn ? Palette.accentTint : Color.clear, in: Capsule())
                .overlay(Capsule().strokeBorder(isOn ? Color.accentColor.opacity(0.5) : Palette.separator, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        // Not .disabled: that dims it, so the one language always in
        // the run looked left out.
        .allowsHitTesting(!isPrimary)
        .help(isPrimary ? Text("Always in the run: picks and the design start from it") : Text(name))
        .accessibilityValue(Text(isOn ? "On" : "Off"))
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("autopilot.plan.language.\(code)")
    }
}
