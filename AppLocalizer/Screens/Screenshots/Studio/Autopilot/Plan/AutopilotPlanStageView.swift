//
//  AutopilotPlanStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Plan: what this run makes (screenshots, App Preview, header and search,
/// per device, the languages, captures reused or not), the screens and how
/// to reach each, then the simulator setup, the design source and
/// checkpoints. Editable until the run starts.
struct AutopilotPlanStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    /// The connected assistant that can run Xcode.
    let assistant: String?
    let isEditable: Bool
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?

    var body: some View {
        ScrollViewReader { proxy in
            scrollView
                // What opens under the screens comes into view.
                .onChange(of: studio.screenDraft != nil) { _, isOpen in
                    if isOpen { scroll(proxy, to: .form, anchor: .bottom) }
                }
                .onChange(of: run.screenRequest != nil) { _, isAsking in
                    if isAsking { scroll(proxy, to: .busy, anchor: .bottom) }
                }
                .onChange(of: run.screenSuggestions?.receivedAt) { _, received in
                    if received != nil { scroll(proxy, to: .suggestions, anchor: .top) }
                }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, to target: AutopilotAddScreensFooter.ScrollTarget, anchor: UnitPoint) {
        withAnimation { proxy.scrollTo(target, anchor: anchor) }
    }

    private var scrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    if let found = studio.planFoundText {
                        Text(found)
                            .accessibilityIdentifier("autopilot.plan.found")
                    }
                    if run.plan.makesScreenshots {
                        Text(studio.planCaptureText(run.plan))
                            .fontWeight(.medium)
                            .accessibilityIdentifier("autopilot.plan.captures")
                    }
                    if !run.plan.targets.isEmpty, let rehearsal = studio.planRehearsalText(run.plan) {
                        Text(rehearsal)
                            .accessibilityIdentifier("autopilot.plan.rehearsal")
                    }
                }
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                // A device this Mac can't capture comes first, before Start.
                if let simulators = macSimulators, !simulators.missing(in: run.plan.runDisplays).isEmpty {
                    AutopilotMacCheckView(studio: studio, plan: run.plan, simulators: simulators)
                }
                AutopilotRunChoiceCard(studio: studio, plan: run.plan, client: client)
                    .disabled(!isEditable)
                capturingPlan
            }
            .padding(Spacing.xLarge)
        }
        .accessibilityIdentifier("autopilot.plan")
    }

    /// The screens, the simulator and the design.
    @ViewBuilder
    private var capturingPlan: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Plan").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
            Spacer()
            Text(source).font(.callout).foregroundStyle(Palette.label2)
            Button(studio.showsPlanScreens ? "Hide Screens" : "Show Screens") { studio.showsPlanScreens.toggle() }
                .buttonStyle(.borderless)
                .font(.callout)
                .accessibilityValue(Text(studio.showsPlanScreens ? "Shown" : "Hidden"))
                .accessibilityIdentifier("autopilot.plan.toggleScreens")
        }
        if studio.showsPlanScreens {
            screens
        } else {
            HStack(spacing: Spacing.small) {
                Text(studio.planScreensSummary(run, client: client))
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isEditable {
                    Button("Add a Screen…") { studio.openScreenForm() }
                        .disabled(studio.plansMaximumScreens)
                        .accessibilityIdentifier("autopilot.plan.summary.addScreen")
                    Button {
                        studio.suggestScreens()
                    } label: {
                        Label("Suggest Screens", systemImage: "sparkles")
                    }
                    .disabled(studio.plansMaximumScreens || run.screenRequest != nil)
                    .accessibilityIdentifier("autopilot.plan.summary.suggestScreens")
                }
            }
            .font(.callout)
            .controlSize(.small)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
            .accessibilityIdentifier("autopilot.plan.screensSummary")
        }
        if let simulators = macSimulators, simulators.missing(in: run.plan.runDisplays).isEmpty, !run.plan.runDisplays.isEmpty {
            AutopilotMacCheckView(studio: studio, plan: run.plan, simulators: simulators)
        }
        Grid(alignment: .topLeading, horizontalSpacing: Spacing.medium, verticalSpacing: Spacing.medium) {
            GridRow {
                AutopilotOptionGroup(title: String(localized: "Simulator")) {
                    AutopilotSimulatorOptions(studio: studio, run: run, assistant: assistant)
                }
                AutopilotOptionGroup(title: String(localized: "Design and checkpoints")) { checkpoints }
            }
        }
        .disabled(!isEditable)
    }

    private var client: String { run.clientName(assistant: assistant) }

    /// Whether the assistant picks the screens, and the screens themselves.
    /// The table keeps its height however long the plan gets.
    @ViewBuilder
    private var screens: some View {
        AutopilotOptionRow(
            title: String(localized: "\(client) picks the screens"),
            detail: String(localized: "It reads the project and replaces these with the screens that show \(studio.app.name) best, before capturing. Off, it keeps yours and writes their steps."),
            isOn: planBinding(\.choosesScreens)
        )
        .disabled(!isEditable)
        .accessibilityIdentifier("autopilot.plan.choosesScreens")
        AutopilotPlanTable(studio: studio, plan: run.plan, client: client, isEditable: isEditable)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// This Mac's simulators, checked while the plan can change.
    private var macSimulators: MacSimulators? { isEditable ? launcher?.simulators : nil }

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

    @ViewBuilder
    private var checkpoints: some View {
        if let project = studio.designProject {
            AutopilotOptionRow(
                title: String(localized: "Design with \(project.kind.title) · \(project.displayName)"),
                detail: run.designDetail(design: project.kind),
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
        AutopilotOptionRow(
            title: String(localized: "Stop for me to watch the App Preview"),
            detail: run.plan.alsoMakes.makesAppPreview
                ? watchDetail
                : String(localized: "Only when the run makes an App Preview"),
            isOn: Binding { run.plan.alsoMakes.makesAppPreview && run.plan.stopsToWatchPreview } set: { value in
                studio.updatePlan { $0.stopsToWatchPreview = value }
            },
            isLocked: !run.plan.alsoMakes.makesAppPreview
        )
        .accessibilityIdentifier("autopilot.plan.stopsToWatch")
        AutopilotOptionRow(title: String(localized: "Review & Push always asks"), detail: nil, isOn: .constant(true), isLocked: true)
    }

    /// "Approve it, or ask Claude Design for changes".
    private var watchDetail: String {
        guard let project = studio.designProject, project.kind.usesDesignAI else { return String(localized: "Play it, then approve it") }
        return String(localized: "Approve it, or ask \(project.kind.title) for changes")
    }

    private func planBinding(_ keyPath: WritableKeyPath<AutopilotPlan, Bool>) -> Binding<Bool> {
        Binding {
            run.plan[keyPath: keyPath]
        } set: { value in
            studio.updatePlan { $0[keyPath: keyPath] = value }
        }
    }
}
