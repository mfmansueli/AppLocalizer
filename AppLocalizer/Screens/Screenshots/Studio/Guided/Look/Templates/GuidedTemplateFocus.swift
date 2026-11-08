//
//  GuidedTemplateFocus.swift
//  AppLocalizer
//

import SwiftUI

/// The previewed template, large: its name, style and tags, what it is,
/// and the pick button; then its screenshots drawn by the real layout
/// engine with the app's captions and captures, on any device the app
/// ships on (a MacBook for Mac, Apple Watch's bare screens; the devices
/// the run doesn't make yet can be added from there) and in any of four
/// languages, each a click from the viewer; and what's worth knowing about
/// it on that device.
struct GuidedTemplateFocus: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    let starter: TemplateStarter
    @State private var preview: GuidedTemplatePreview?
    /// What `preview` was laid out for.
    @State private var previewKey: Key?

    var body: some View {
        let number = studio.shotTemplateNumber(starter)
        let device = studio.templatePreviewDevice(plan)
        let locale = studio.templatePreviewLocale(plan)
        let key = Key(
            starter: starter, device: device, locale: locale, hasDocument: studio.screenshots.document != nil,
            isInRun: studio.templatePreviewIsInRun(device, plan: plan), ratings: studio.screenshots.ratings,
            reviews: studio.screenshots.reviews
        )
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .top, spacing: Spacing.large) {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    FlowLayout(spacing: Spacing.xSmall) {
                        Text("Previewing").font(.caption).foregroundStyle(Palette.label2)
                        Text(starter.title)
                            .font(.title3.weight(.semibold))
                            .accessibilityIdentifier("autopilot.guided.look.template.focusName")
                        Pill(text: starter.style.title, style: .neutral)
                        ForEach(starter.tags, id: \.self) { tag in Pill(text: tag, style: .outline) }
                        if isInUse { Pill(text: String(localized: "In use now"), style: .accent) }
                    }
                    Text(starter.summary)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                pickButton(number: number)
            }
            .id(GuidedLookScrollTarget.templateFocus)
            controls(device: device, locale: locale)
            if let preview, previewKey == key {
                if !preview.isInRun {
                    GuidedTemplateNotInRun(studio: studio, preview: preview)
                }
                GuidedTemplateStrip(studio: studio, plan: plan, preview: preview)
                note(preview)
            } else {
                placeholders
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1)
        .task(id: key) {
            // Laid out again once the ratings and reviews arrive.
            studio.screenshots.lookUpRatings(for: starter)
            studio.screenshots.lookUpReviews(for: starter)
            preview = studio.templatePreview(starter, plan: plan)
            previewKey = key
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.look.template.focus")
    }

    private struct Key: Hashable {
        var starter: TemplateStarter
        var device: ScreenshotDisplayType
        var locale: String
        var hasDocument: Bool
        var isInRun: Bool
        var ratings: StoreRatings
        var reviews: StoreReviews
    }

    /// What's worth knowing on the device, then how many devices the run
    /// makes when some are only previewed.
    private func note(_ preview: GuidedTemplatePreview) -> some View {
        let count = GuidedTemplatePreviewDevices.runCount(studio.templatePreviewDevices(plan), inRun: plan.displayTypes + [.iPhone])
        let text = Text(preview.note).foregroundStyle(Palette.label2)
        return Group {
            if let count {
                Text("\(text) \(Text(count).foregroundStyle(Palette.label3))")
            } else {
                text
            }
        }
        .font(.callout)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("autopilot.guided.look.template.note")
    }

    static var aspect: Double {
        let size = ScreenshotDisplayType.iPhone.portraitPixelSize
        return Double(size.height) / Double(max(size.width, 1))
    }

    private var isInUse: Bool { studio.screenshots.document?.template?.starter == starter }

    /// The device, the language, and the screenshots' size: on one row
    /// where they fit, else the size under the switches, else each on its
    /// own line (six devices and four languages), never cut or wider than
    /// the card.
    private func controls(device: ScreenshotDisplayType, locale: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                deviceSwitch(device)
                languageSwitch(locale)
                Spacer(minLength: Spacing.small)
                sizeLine(device)
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(spacing: 10) {
                    deviceSwitch(device)
                    languageSwitch(locale)
                }
                sizeLine(device)
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                deviceSwitch(device)
                languageSwitch(locale)
                sizeLine(device)
            }
        }
    }

    @ViewBuilder
    private func deviceSwitch(_ device: ScreenshotDisplayType) -> some View {
        let devices = studio.templatePreviewDevices(plan)
        if devices.count > 1 {
            StudioSegmentedControl(
                label: String(localized: "Preview device"),
                options: devices.map { device in
                    let isInRun = studio.templatePreviewIsInRun(device, plan: plan)
                    return .init(
                        value: device, title: GuidedTemplatePreviewDevices.label(device, isInRun: isInRun),
                        key: GuidedTemplatePreviewDevices.key(device), help: GuidedTemplatePreviewDevices.help(device, isInRun: isInRun),
                        isDimmed: !isInRun
                    )
                },
                selection: Binding { device } set: { studio.guided.templateDevice = $0 },
                identifier: "autopilot.guided.look.template.device"
            )
        }
    }

    @ViewBuilder
    private func languageSwitch(_ locale: String) -> some View {
        let locales = studio.templatePreviewLocales(plan)
        if locales.count > 1 {
            StudioSegmentedControl(
                label: String(localized: "Preview language"),
                options: locales.map { .init(value: $0, title: GuidedPreviewLocales.title(of: $0, among: locales), key: $0) },
                selection: Binding { locale } set: { studio.guided.templateLocale = $0 },
                identifier: "autopilot.guided.look.template.locale"
            )
        }
    }

    /// "iPad 13″ · 2752 × 2064 · click a screenshot to see it larger".
    private func sizeLine(_ device: ScreenshotDisplayType) -> some View {
        Text("\(previewKey?.device == device ? preview?.sizeTitle ?? "" : GuidedTemplatePreviewDevices.sizeTitle(device)) · click a screenshot to see it larger")
            .font(.caption)
            .foregroundStyle(Palette.label2)
            .lineLimit(1)
            .fixedSize()
            .accessibilityIdentifier("autopilot.guided.look.template.size")
    }

    /// Five empty screenshots while the set is read.
    private var placeholders: some View {
        HStack(spacing: 10) {
            ForEach(0..<StarterPreview.slotCount, id: \.self) { _ in
                StudioShotImage(image: nil, width: 124, aspect: Self.aspect)
            }
        }
    }

    @ViewBuilder
    private func pickButton(number: Int?) -> some View {
        let title = GuidedPickToggle.title(number: number, picked: studio.shotTemplatePicks.count)
        let label = Text(title).frame(minWidth: 150)
        if GuidedPickToggle.isProminent(number: number) {
            Button { studio.toggleShotTemplate(starter) } label: { label }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .accessibilityLabel(Text(title))
                .accessibilityIdentifier("autopilot.guided.look.template.pick")
        } else {
            Button { studio.toggleShotTemplate(starter) } label: { label }
                .buttonBorderShape(.capsule)
                .accessibilityLabel(Text(title))
                .accessibilityIdentifier("autopilot.guided.look.template.pick")
        }
    }
}
