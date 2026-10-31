//
//  AutopilotSheetHeader.swift
//  AppLocalizer
//

import SwiftUI

/// "Screenshot Autopilot", the run's scope, and Close (Hide while it runs).
struct AutopilotSheetHeader: View {
    let appName: String
    let run: AutopilotRun
    let hides: Bool
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: "camera")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.machineTranslated)
                .frame(width: 34, height: 34)
                .background(Palette.machineTranslatedTint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.tiny) {
                Text("Screenshot Autopilot")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("\(appName) \(run.versionString) · \(run.plan.scopeTitle)")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("autopilot.scope")
            }
            Spacer()
            Button(hides ? String(localized: "Hide") : String(localized: "Close"), action: onClose)
                .buttonBorderShape(.capsule)
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("autopilot.close")
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }
}
