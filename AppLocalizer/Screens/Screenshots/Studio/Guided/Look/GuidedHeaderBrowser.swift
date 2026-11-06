//
//  GuidedHeaderBrowser.swift
//  AppLocalizer
//

import SwiftUI

/// Start from scene templates: the six scenes sketched in the app's
/// colors (the recommended one marked), the one clicked previewed large
/// with its search image, what it fits and how it loops, and My picks.
struct GuidedHeaderBrowser: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan

    var body: some View {
        let picks = studio.headerTemplatePicks
        let recommended = studio.headerRecommendation.template
        let focus = studio.guided.headerFocus ?? picks.first ?? recommended
        let colors = studio.headerSketchColors
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.small) {
                ForEach(AutopilotHeaderTemplate.allCases) { template in
                    card(template, isFocused: template == focus, number: picks.firstIndex(of: template).map { $0 + 1 }, isRecommended: template == recommended)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Scene templates"))
            .accessibilityIdentifier("autopilot.guided.look.scenes")
            Divider()
            focusView(focus, isRecommended: focus == recommended, colors: colors)
            Divider()
            GuidedPicksTray(
                picks: picks,
                text: picks.isEmpty
                    ? String(localized: "Nothing picked yet. Preview a scene above, then Add to My Picks.")
                    : String(localized: "\(studio.headerDesignerName) makes one header from each pick, fitted to \(studio.app.name). You choose one after it’s made."),
                emptyHeight: 57,
                identifier: "autopilot.guided.look.scene.tray",
                name: \.name,
                preview: { studio.guided.headerFocus = $0 },
                remove: { studio.toggleHeaderTemplate($0) },
                thumbnail: { template in
                    HeaderTemplateSketch(template: template, light: colors.light, dark: colors.dark, width: 104)
                }
            )
        }
        .modifier(GuidedSelectableCard(padding: 0))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .onAppear { studio.fillHeaderTemplates() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.look.sceneBrowser")
    }

    private func card(_ template: AutopilotHeaderTemplate, isFocused: Bool, number: Int?, isRecommended: Bool) -> some View {
        let colors = studio.headerSketchColors
        return Button {
            studio.guided.headerFocus = template
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                // Six fit the sheet at its narrowest (960 pt).
                HeaderTemplateSketch(template: template, light: colors.light, dark: colors.dark, width: 120)
                    .overlay(alignment: .topTrailing) {
                        if let number {
                            Text("\(number)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .background(Palette.accent, in: Circle())
                                .padding(3)
                        }
                    }
                Text(template.name).font(.caption.weight(.semibold)).lineLimit(1)
                if isRecommended {
                    Text("Recommended").font(.caption).foregroundStyle(Palette.accentText)
                }
            }
            .padding(5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isFocused ? Palette.accentTint : Color.clear, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(number != nil ? Palette.accent : Color.clear, lineWidth: 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(cardLabel(template, number: number, isRecommended: isRecommended)))
        .accessibilityAddTraits(isFocused ? .isSelected : [])
        .accessibilityIdentifier("autopilot.guided.look.scene.\(template.rawValue)")
    }

    private func focusView(_ template: AutopilotHeaderTemplate, isRecommended: Bool, colors: (light: Color, dark: Color)) -> some View {
        let number = studio.headerTemplatePicks.firstIndex(of: template).map { $0 + 1 }
        return HStack(alignment: .top, spacing: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HeaderTemplateSketch(template: template, light: colors.light, dark: colors.dark, isMoving: plan.alsoMakes.makesMotion, width: 470)
                HStack(alignment: .bottom, spacing: Spacing.small) {
                    if plan.alsoMakes.artworkSize.searchKind == .search {
                        ArtworkSketch(kind: .search, shows: plan.alsoMakes.artworkShows, width: 170)
                    }
                    Text("Header above, search result left. A sketch of the scene type in \(studio.app.name)’s colors; \(studio.headerDesignerName) makes the real one.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .frame(maxWidth: 280, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Previewing").font(.caption).foregroundStyle(Palette.label2)
                Text(template.name)
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("autopilot.guided.look.scene.focusName")
                if isRecommended {
                    Pill(text: String(localized: "Recommended"), style: .accent)
                }
                Text("\(template.summary). \(String(localized: "Fits \(template.fits.lowercased()).")) ")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                if plan.alsoMakes.makesMotion {
                    Text("Loop: \(template.loop.prefix(1).lowercased() + template.loop.dropFirst()).")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if isRecommended {
                    Text(studio.headerRecommendation.text(appName: studio.app.name))
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("autopilot.guided.look.scene.recommendation")
                }
                Spacer(minLength: Spacing.small)
                let title = GuidedPickToggle.title(number: number, picked: studio.headerTemplatePicks.count)
                if GuidedPickToggle.isProminent(number: number) {
                    Button(title) { studio.toggleHeaderTemplate(template) }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .accessibilityIdentifier("autopilot.guided.look.scene.pick")
                } else {
                    Button(title) { studio.toggleHeaderTemplate(template) }
                        .buttonBorderShape(.capsule)
                        .accessibilityIdentifier("autopilot.guided.look.scene.pick")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.look.scene.focus")
    }

    /// "Day to Night, pick 1, recommended".
    private func cardLabel(_ template: AutopilotHeaderTemplate, number: Int?, isRecommended: Bool) -> String {
        var parts = [template.name]
        if let number { parts.append(String(localized: "pick \(number)")) }
        if isRecommended { parts.append(String(localized: "recommended")) }
        return parts.joined(separator: ", ")
    }
}
