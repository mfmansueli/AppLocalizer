//
//  ScreenshotsPageHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The top of Screenshots: what it changes on the App Store, the language
/// in view | All Languages, Start Autopilot…, and More (the App Store
/// preview with Autopilot, Sets, Template, Captions, Captures).
struct ScreenshotsPageHeader: View {
    @Bindable var viewModel: ScreenshotsViewModel
    /// Nil in previews and scenes without the app's gate.
    @Environment(ProGate.self) private var pro: ProGate?

    var body: some View {
        SectionHeader(
            systemImage: "iphone",
            tint: Palette.sectionScreenshots,
            title: String(localized: "Screenshots"),
            subtitle: String(localized: "The images people swipe through on \(viewModel.app.name)’s App Store page, per language and device.")
        ) {
            Picker("View", selection: $viewModel.pageShowsAll) {
                Text(LanguageBarModel.shortName(viewModel.currentPageLocale)).tag(false)
                Text("All Languages").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .accessibilityIdentifier("screenshots.page.view")
            Button {
                // A run under way opens as it is; starting one is Pro's.
                let open = {
                    viewModel.tab = .preview
                    viewModel.studio.openOrStartGuidedAutopilot()
                }
                if Self.startsRun(stage: viewModel.studio.run?.stage) { pro.require(.autopilot, then: open) } else { open() }
            } label: {
                HStack(spacing: Spacing.xSmall) {
                    Label(Self.autopilotTitle(stage: viewModel.studio.run?.stage), systemImage: "wand.and.stars")
                    if pro.isFree, Self.startsRun(stage: viewModel.studio.run?.stage) { ProChip() }
                }
            }
            .buttonBorderShape(.capsule)
            .accessibilityIdentifier("screenshots.page.autopilot")
            moreMenu
        }
    }

    /// "Start Autopilot…" until a run is under way; then the button opens
    /// that run, and says so.
    static func autopilotTitle(stage: AutopilotStage?) -> String {
        startsRun(stage: stage) ? String(localized: "Start Autopilot…") : String(localized: "Open Autopilot…")
    }

    /// No run yet, or one still being set up: the button starts one.
    static func startsRun(stage: AutopilotStage?) -> Bool {
        stage == nil || stage == .plan
    }

    private var moreMenu: some View {
        Menu {
            Button("App Store Preview & Autopilot") { viewModel.tab = .preview }
            Divider()
            ForEach(ScreenshotsTab.allCases.filter { $0 != .preview }, id: \.self) { tab in
                Button(tab.title) { viewModel.tab = tab }
            }
        } label: {
            Label("More", systemImage: "ellipsis")
                .labelStyle(.iconOnly)
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Sets, the template, captions and captures")
        .accessibilityIdentifier("screenshots.page.more")
    }
}
