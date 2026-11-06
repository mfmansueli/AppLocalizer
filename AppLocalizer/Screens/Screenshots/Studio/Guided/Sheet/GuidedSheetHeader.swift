//
//  GuidedSheetHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The guided sheet's top: "New App Store assets", what this run makes,
/// and Cancel while it's set up, Hide · Keeps Going while it runs, Close
/// once it's sent.
struct GuidedSheetHeader: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let step: GuidedStep

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.accent)
                .frame(width: 34, height: 34)
                .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(step == .done ? String(localized: "Sent to the App Store") : String(localized: "New App Store assets"))
                    .font(.headline)
                    .accessibilityIdentifier("autopilot.guided.sheetTitle")
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityIdentifier("autopilot.guided.sheetSubtitle")
            }
            Spacer(minLength: Spacing.small)
            if step.isSetup {
                Button("Cancel") { studio.cancelPlan() }
                    .buttonBorderShape(.capsule)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("autopilot.guided.cancel")
            } else if step == .done {
                Button("Close") { studio.isAutopilotPresented = false }
                    .buttonBorderShape(.capsule)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("autopilot.guided.close")
            } else {
                Button("Hide · Keeps Going") { studio.isAutopilotPresented = false }
                    .buttonBorderShape(.capsule)
                    .keyboardShortcut(.cancelAction)
                    .help(Text("Autopilot keeps going. You’ll get a notification when it needs you."))
                    .accessibilityIdentifier("autopilot.guided.hide")
            }
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.top, Spacing.medium)
        .padding(.bottom, Spacing.small)
    }

    /// "Lumen Journal 1.4 · set up a run in 3 steps", then what it makes.
    private var subtitle: String {
        let app = "\(studio.app.name) \(run.versionString)"
        guard !step.isSetup else { return String(localized: "\(app) · set up a run in 3 steps") }
        guard let made = GuidedMakeSummary.made(run.plan) else { return app }
        return "\(app) · \(made)"
    }
}
