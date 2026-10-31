//
//  AutopilotPlanStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Plan: the screens and how to reach each, then devices, languages,
/// simulator setup, the design source and checkpoints. Editable until the
/// run starts.
struct AutopilotPlanStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    /// The connected assistant that can run Xcode.
    let assistant: String?
    let isEditable: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                if let found = studio.planFoundText {
                    Text(found)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.small)
                        .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                        .accessibilityIdentifier("autopilot.plan.found")
                }
                HStack(alignment: .firstTextBaseline) {
                    Text("Plan").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text(source).font(.callout).foregroundStyle(Palette.label2)
                }
                AutopilotOptionRow(
                    title: String(localized: "\(client) picks the screens"),
                    detail: String(localized: "It reads the project and replaces these with the screens that show \(studio.app.name) best, before capturing. Off, it keeps yours and writes their steps."),
                    isOn: planBinding(\.choosesScreens)
                )
                .disabled(!isEditable)
                .accessibilityIdentifier("autopilot.plan.choosesScreens")
                AutopilotPlanTable(studio: studio, plan: run.plan, client: client, isEditable: isEditable)
                Grid(alignment: .topLeading, horizontalSpacing: Spacing.medium, verticalSpacing: Spacing.medium) {
                    GridRow {
                        AutopilotOptionGroup(title: String(localized: "Devices")) { devices }
                        AutopilotOptionGroup(title: String(localized: "Languages")) { languages }
                    }
                    GridRow {
                        AutopilotOptionGroup(title: String(localized: "Simulator")) { simulator }
                        AutopilotOptionGroup(title: String(localized: "Design and checkpoints")) { checkpoints }
                    }
                }
                .disabled(!isEditable)
            }
            .padding(Spacing.xLarge)
        }
        .accessibilityIdentifier("autopilot.plan")
    }

    private var client: String { run.clientName(assistant: assistant) }

    private var source: String {
        if let file = run.plan.writtenFrom {
            return String(localized: "Written by \(client) from \(file). Edit anything.")
        }
        if run.plan.screens.isEmpty {
            return String(localized: "\(run.clientName(assistant: assistant, startsSentence: true)) writes the screens from your code when it picks up the plan.")
        }
        if run.plan.choosesScreens {
            return String(localized: "From your set’s slots, for now: \(client) picks the screens when it picks up the plan.")
        }
        return String(localized: "From your set’s slots. \(client) writes the steps; edit anything.")
    }

    private var devices: some View {
        ForEach(studio.planDevices(run.plan), id: \.self) { display in
            AutopilotOptionRow(
                title: display.title,
                detail: studio.planDeviceDetail(display, plan: run.plan),
                isOn: display == .iPhone ? .constant(true) : deviceBinding(display),
                isLocked: display == .iPhone
            )
            .accessibilityIdentifier("autopilot.plan.\(display == .iPad ? "iPad" : display.mcpValue)")
        }
    }

    @ViewBuilder
    private var languages: some View {
        AutopilotOptionRow(title: studio.storeLanguagesTitle(run.plan), detail: nil, isOn: .constant(true), isLocked: true)
        if let new = studio.newLanguagesTitle(run.plan) {
            AutopilotOptionRow(
                title: new,
                detail: studio.newLanguagesDetail,
                isOn: Binding { run.plan.includesNewLanguages } set: { studio.setIncludesNewLanguages($0) }
            )
            .accessibilityIdentifier("autopilot.plan.newLanguages")
        }
        AutopilotOptionRow(
            title: String(localized: "Capture the app in each language"),
            detail: String(localized: "Launches with -AppleLanguages; otherwise \(studio.primaryLocale.shortName) captures are reused under translated captions"),
            isOn: planBinding(\.capturesEachLanguage)
        )
        .accessibilityIdentifier("autopilot.plan.eachLanguage")
    }

    private func deviceBinding(_ display: ScreenshotDisplayType) -> Binding<Bool> {
        Binding {
            run.plan.displayTypes.contains(display)
        } set: { planned in
            studio.setPlans(display, planned)
        }
    }

    @ViewBuilder
    private var simulator: some View {
        AutopilotOptionRow(
            title: String(localized: "Status bar at 9:41, full battery and signal"),
            detail: "xcrun simctl status_bar override",
            isOn: planBinding(\.simulator.overridesStatusBar)
        )
        AutopilotOptionRow(
            title: String(localized: "Sample data"),
            detail: run.plan.simulator.sampleDataSteps.isEmpty
                ? String(localized: "\(run.clientName(assistant: assistant, startsSentence: true)) finds the app’s sample-data switch")
                : run.plan.simulator.sampleDataSteps,
            isOn: planBinding(\.simulator.usesSampleData)
        )
        AutopilotOptionRow(
            title: String(localized: "Light appearance, no notifications"),
            detail: nil,
            isOn: planBinding(\.simulator.lightAppearance)
        )
        ForEach(run.plan.simulator.extraCommands, id: \.self) { command in
            AutopilotOptionRow(title: String(localized: "Added by a fix"), detail: command, isOn: .constant(true), isLocked: true)
        }
    }

    @ViewBuilder
    private var checkpoints: some View {
        if let project = studio.designProject {
            AutopilotOptionRow(
                title: String(localized: "Design with \(project.kind.title) · \(project.displayName)"),
                detail: String(localized: "\(AutopilotRun.directionCount) directions"),
                isOn: .constant(true), isLocked: true
            )
        } else {
            HStack {
                AutopilotOptionRow(
                    title: String(localized: "AppLocalizer’s starters"),
                    detail: String(localized: "Colored from the app icon"),
                    isOn: .constant(true), isLocked: true
                )
                Button("Connect…") { studio.isDesignProjectPresented = true }
                    .controlSize(.small)
                    .accessibilityIdentifier("autopilot.plan.connectDesign")
            }
        }
        AutopilotOptionRow(title: String(localized: "Stop for me to pick captures"), detail: nil, isOn: planBinding(\.stopsToPick))
            .accessibilityIdentifier("autopilot.plan.stopsToPick")
        AutopilotOptionRow(title: String(localized: "Stop for me to choose the direction"), detail: nil, isOn: planBinding(\.stopsToChoose))
            .accessibilityIdentifier("autopilot.plan.stopsToChoose")
        AutopilotOptionRow(title: String(localized: "Review & Push always asks"), detail: nil, isOn: .constant(true), isLocked: true)
    }

    private func planBinding(_ keyPath: WritableKeyPath<AutopilotPlan, Bool>) -> Binding<Bool> {
        Binding {
            run.plan[keyPath: keyPath]
        } set: { value in
            studio.updatePlan { $0[keyPath: keyPath] = value }
        }
    }
}
