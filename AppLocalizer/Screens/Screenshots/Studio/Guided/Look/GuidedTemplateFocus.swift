//
//  GuidedTemplateFocus.swift
//  AppLocalizer
//

import SwiftUI

/// The previewed template, large: its first five slots with the app's
/// captions and captures in the language chosen, its name, style and
/// tags, what it is, and the pick button.
struct GuidedTemplateFocus: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    let starter: TemplateStarter
    @State private var jobs: [RenderJob] = []

    var body: some View {
        let locale = studio.guided.templateLocale ?? plan.primaryLocale
        let number = studio.shotTemplateNumber(starter)
        HStack(alignment: .top, spacing: 18) {
            HStack(spacing: Spacing.small) {
                if jobs.isEmpty {
                    ForEach(0..<StarterPreview.slotCount, id: \.self) { _ in
                        StudioShotImage(image: nil, width: 108, aspect: Self.aspect)
                    }
                } else {
                    ForEach(Array(jobs.enumerated()), id: \.offset) { index, job in
                        GuidedJobImage(studio: studio, job: job, width: 108, label: String(localized: "\(starter.title), screenshot \(index + 1)"))
                            .shadow(color: .black.opacity(0.14), radius: 5, y: 2)
                    }
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Previewing").font(.caption).foregroundStyle(Palette.label2)
                Text(starter.title)
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("autopilot.guided.look.template.focusName")
                FlowLayout(spacing: Spacing.xxSmall) {
                    Pill(text: starter.style.title, style: .neutral)
                    ForEach(starter.tags, id: \.self) { tag in Pill(text: tag, style: .outline) }
                    if isInUse { Pill(text: String(localized: "In use now"), style: .accent) }
                }
                Text(starter.summary)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                let locales = GuidedPreviewLocales.pick(from: plan.localeCodes, primary: plan.primaryLocale)
                if locales.count > 1 {
                    StudioSegmentedControl(
                        label: String(localized: "Preview language"),
                        options: locales.map { .init(value: $0, title: GuidedPreviewLocales.language(of: $0), key: $0) },
                        selection: Binding { locale } set: { studio.guided.templateLocale = $0 },
                        identifier: "autopilot.guided.look.template.locale"
                    )
                }
                Spacer(minLength: Spacing.small)
                pickButton(number: number)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1)
        .task(id: Key(starter: starter, locale: locale)) {
            jobs = studio.screenshots.starterJobs(starter, locale: locale)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.look.template.focus")
    }

    private struct Key: Hashable {
        var starter: TemplateStarter
        var locale: String
    }

    static var aspect: Double {
        let size = ScreenshotDisplayType.iPhone.portraitPixelSize
        return Double(size.height) / Double(max(size.width, 1))
    }

    private var isInUse: Bool { studio.screenshots.document?.template?.starter == starter }

    @ViewBuilder
    private func pickButton(number: Int?) -> some View {
        let title = GuidedPickToggle.title(number: number, picked: studio.shotTemplatePicks.count)
        if GuidedPickToggle.isProminent(number: number) {
            Button(title) { studio.toggleShotTemplate(starter) }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("autopilot.guided.look.template.pick")
        } else {
            Button(title) { studio.toggleShotTemplate(starter) }
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("autopilot.guided.look.template.pick")
        }
    }
}
