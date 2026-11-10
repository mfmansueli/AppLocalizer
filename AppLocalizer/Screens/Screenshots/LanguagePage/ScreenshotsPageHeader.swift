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
                viewModel.tab = .preview
                viewModel.studio.runGuidedAutopilot()
            } label: {
                Label("Start Autopilot…", systemImage: "wand.and.stars")
            }
            .buttonBorderShape(.capsule)
            .accessibilityIdentifier("screenshots.page.autopilot")
            moreMenu
        }
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
