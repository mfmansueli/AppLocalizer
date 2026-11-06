//
//  GuidedLanguagesRow.swift
//  AppLocalizer
//

import SwiftUI

/// What to make's languages: every language on the App Store, the primary
/// one only, or chosen ones, and the app's languages the App Store page
/// doesn't have yet.
struct GuidedLanguagesRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.medium) {
                Text("Languages")
                    .font(.callout.weight(.semibold))
                    .frame(width: 90, alignment: .leading)
                if plan.availableLocaleCodes.count <= 1 {
                    onlyLanguage
                } else {
                    choices
                }
                Spacer(minLength: 0)
            }
            if plan.runChoice.languages == .chosen, plan.availableLocaleCodes.count > 1 {
                AutopilotLanguageChips(studio: studio, plan: plan)
                    .padding(.leading, 90 + Spacing.medium)
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, 10)
        .modifier(GuidedSelectableCard(padding: 0))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.make.languageRow")
    }

    /// An app with one language (MB Admin: Portuguese on the App Store and
    /// in the app) was offered "The App Store’s language", "Portuguese
    /// (Brazil) only" and an empty Choose…, three names for one thing.
    private var onlyLanguage: some View {
        let detail = plan.newLocaleCodes == nil
            ? String(localized: "the App Store page’s only language")
            : String(localized: "the only language on the App Store page and in the app")
        return Text("\(GuidedMakeSummary.primaryName(plan)) \(Text("· \(detail)").foregroundStyle(Palette.label2))")
            .font(.callout)
            .accessibilityIdentifier("autopilot.guided.make.languages.only")
    }

    @ViewBuilder
    private var choices: some View {
        StudioSegmentedControl(
            label: String(localized: "Languages"),
            options: AutopilotLanguageMode.allCases.map { .init(value: $0, title: title($0), key: $0.rawValue) },
            selection: Binding { plan.runChoice.languages } set: { studio.setLanguageMode($0) },
            identifier: "autopilot.guided.make.languages"
        )
        if plan.runChoice.languages == .all, let include = studio.includeNewLanguagesTitle(plan) {
            Toggle(include, isOn: Binding { plan.includesNewLanguages } set: { studio.setIncludesNewLanguages($0) })
                .toggleStyle(.checkbox)
                .font(.callout)
                .help(Text(studio.newLanguagesDetail))
                .accessibilityIdentifier("autopilot.guided.make.newLanguages")
        }
    }

    /// "All 18 languages", "English only", "Choose…".
    private func title(_ mode: AutopilotLanguageMode) -> String {
        switch mode {
        case .all:
            let count = plan.storeLocaleCodes.count + (plan.runChoice.languages == .all ? plan.addedLocaleCodes.count : 0)
            return count == 1 ? String(localized: "The App Store’s language") : String(localized: "All \(count) languages")
        case .primary:
            return String(localized: "\(GuidedMakeSummary.primaryName(plan)) only")
        case .chosen:
            return String(localized: "Choose…")
        }
    }
}
