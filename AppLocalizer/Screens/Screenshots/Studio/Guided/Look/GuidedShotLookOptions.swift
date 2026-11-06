//
//  GuidedShotLookOptions.swift
//  AppLocalizer
//

import SwiftUI

/// The screenshots' three looks: a new one from the designer, one made
/// from gallery templates, or the current one with new captures and
/// captions.
struct GuidedShotLookOptions: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    let liveShots: [StudioShot]

    var body: some View {
        let style = plan.screenshotStyle
        let version = studio.keptTemplateVersion
        HStack(alignment: .top, spacing: Spacing.medium) {
            GuidedOptionCard(
                title: String(localized: "A new look from \(studio.shotStyleDesigner)"),
                text: newLookText,
                isSelected: style == .free,
                identifier: "autopilot.guided.look.shotStyle.free",
                action: { studio.setShotStyle(.free) },
                preview: { strip { newLookPlaceholders } }
            )
            GuidedOptionCard(
                title: String(localized: "Start from templates"),
                text: templatesText,
                isSelected: style == .templates,
                identifier: "autopilot.guided.look.shotStyle.templates",
                action: { studio.setShotStyle(.templates) },
                preview: { strip { templateThumbnails } }
            )
            GuidedOptionCard(
                title: String(localized: "Keep your current look"),
                text: keepText(version: version),
                isSelected: style == .keep,
                isInUse: version != nil,
                isEnabled: version != nil,
                identifier: "autopilot.guided.look.shotStyle.keep",
                action: { studio.setShotStyle(.keep) },
                preview: { strip { liveThumbnails } }
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.look.shotStyle")
    }

    private var newLookText: String {
        guard let brand = studio.shotStyleBrand else { return String(localized: "3 new looks to choose from") }
        return String(localized: "3 new looks in \(brand) to choose from")
    }

    /// With the app's screens only when there are captures to show.
    private var templatesText: String {
        let count = TemplateStarter.allCases.count
        guard studio.screenshots.document?.captures.isEmpty == false else {
            return String(localized: "Browse the \(count) templates and pick up to 3")
        }
        return String(localized: "Browse the \(count) templates with \(studio.app.name)’s screens and pick up to 3")
    }

    /// "Caption above device (v4), with new captures and captions".
    private func keepText(version: Int?) -> String {
        guard let version else { return String(localized: "This set has no template yet") }
        let name = studio.screenshots.document?.template?.starter?.title ?? studio.screenshots.document?.template?.name ?? String(localized: "Your template")
        return String(localized: "\(name) (v\(version)), with new captures and captions")
    }

    private func strip(@ViewBuilder _ content: () -> some View) -> some View {
        HStack(spacing: Spacing.xxSmall) { content() }
            .frame(maxWidth: .infinity)
            .padding(Spacing.small)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Spacing.small, style: .continuous))
            .accessibilityHidden(true)
    }

    private var newLookPlaceholders: some View {
        ForEach(0..<3, id: \.self) { index in
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Palette.accentTint)
                .frame(width: 50, height: (50 * GuidedTemplateFocus.aspect).rounded())
                .overlay {
                    if index == 1 {
                        Image(systemName: "sparkles").font(.system(size: 16)).foregroundStyle(Palette.accent)
                    }
                }
        }
    }

    @ViewBuilder
    private var templateThumbnails: some View {
        let picks = studio.shotTemplatePicks
        let starters = picks.isEmpty ? [TemplateStarter.boldStack, .cinema, .editorial] : picks
        ForEach(starters, id: \.self) { starter in
            StudioShotImage(image: studio.screenshots.starterImages(starter).first ?? nil, width: 50, aspect: GuidedTemplateFocus.aspect)
        }
    }

    @ViewBuilder
    private var liveThumbnails: some View {
        if liveShots.isEmpty {
            // Empty slots: a missing image would show a spinner, as if the
            // set were still loading.
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Palette.separator, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .frame(width: 50, height: (50 * GuidedTemplateFocus.aspect).rounded())
            }
        } else {
            ForEach(liveShots) { shot in
                GuidedShotImage(studio: studio, shot: shot, width: 50)
            }
        }
    }
}
