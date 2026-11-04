//
//  AutopilotScreenForm.swift
//  AppLocalizer
//

import SwiftUI

/// "+ Add a Screen…": name, how to get there (or the assistant works it out
/// and adds it to the UI tests), and the caption in the primary language.
/// Apple Watch's has no caption: its screenshots are the captures.
struct AutopilotScreenForm: View {
    @Bindable var studio: ScreenshotStudioModel
    let client: String

    var body: some View {
        let draft = Binding { studio.screenDraft ?? AutopilotScreenDraft() } set: { studio.screenDraft = $0 }
        let display = draft.wrappedValue.displayType
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(display == .watch ? "New Apple Watch screen" : "New screen").font(.callout.weight(.semibold)).accessibilityAddTraits(.isHeader)
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: Spacing.small, verticalSpacing: Spacing.xSmall) {
                GridRow {
                    Text("Name").foregroundStyle(Palette.label2)
                    TextField(display == .watch ? String(localized: "e.g. Today’s mood") : String(localized: "e.g. Insights"), text: draft.name)
                        .accessibilityIdentifier("autopilot.plan.form.name")
                }
                GridRow {
                    Text("How to get there").foregroundStyle(Palette.label2)
                    TextField(stepsPlaceholder(display), text: draft.steps)
                        .font(.system(.callout, design: .monospaced))
                        .disabled(draft.wrappedValue.worksOutSteps)
                        .accessibilityIdentifier("autopilot.plan.form.steps")
                }
                GridRow {
                    Color.clear.frame(width: 1, height: 1)
                    Toggle(String(localized: "Let \(client) work out the steps and add them to \(studio.uiTestsName(on: display))"), isOn: draft.worksOutSteps)
                        .toggleStyle(.checkbox)
                        .accessibilityIdentifier("autopilot.plan.form.worksOutSteps")
                }
                if display.hasCaptions {
                    GridRow {
                        Text("Caption · \(studio.primaryLocale.shortName)").foregroundStyle(Palette.label2)
                        TextField(String(localized: "Optional · empty lets \(client) write it"), text: draft.caption)
                            .accessibilityIdentifier("autopilot.plan.form.caption")
                    }
                }
            }
            .font(.callout)
            .textFieldStyle(.roundedBorder)
            HStack {
                Text(captureNote(display))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("autopilot.plan.form.note")
                Spacer()
                Button("Cancel") { studio.screenDraft = nil }
                    .accessibilityIdentifier("autopilot.plan.form.cancel")
                Button("Add Screen") { studio.addDraftScreen() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!draft.wrappedValue.canAdd || studio.plansMaximumScreens(on: display))
                    .accessibilityIdentifier("autopilot.plan.form.add")
            }
            .controlSize(.small)
        }
        .padding(Spacing.medium)
        .background(Palette.fill1.opacity(0.5), in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.form")
    }

    private func stepsPlaceholder(_ display: ScreenshotDisplayType) -> String {
        display == .watch
            ? String(localized: "e.g. scroll the crown to Today → tap the mood ring")
            : String(localized: "e.g. tab “Insights” → wait for the chart")
    }

    /// Where the new screen is captured.
    private func captureNote(_ display: ScreenshotDisplayType) -> String {
        display == .watch
            ? String(localized: "Captured on Apple Watch, paired with the iPhone simulator, like the other watch screens. No caption.")
            : String(localized: "Captured on iPhone and iPad like the other screens.")
    }
}
