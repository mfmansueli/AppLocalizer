//
//  GuidedTemplateBrowser.swift
//  AppLocalizer
//

import SwiftUI

/// Start from templates: every gallery template as a thumbnail with the
/// app's screens (filtered by style), the one clicked previewed large,
/// and My picks, the up to three Claude Design makes a look from.
struct GuidedTemplateBrowser: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan

    var body: some View {
        let picks = studio.shotTemplatePicks
        let focus = studio.guided.templateFocus ?? picks.first ?? .cinema
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text("Templates").font(.callout.weight(.semibold))
                TemplateStyleFilter(style: $studio.guided.templateStyle)
                Spacer(minLength: Spacing.small)
                Text("Click one to see it with \(studio.app.name)’s screens")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            Divider()
            HStack(alignment: .top, spacing: 5) {
                ForEach(TemplateStarter.starters(in: studio.guided.templateStyle)) { starter in
                    thumbnail(starter, isFocused: starter == focus)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Templates"))
            .accessibilityIdentifier("autopilot.guided.look.templates")
            Divider()
            GuidedTemplateFocus(studio: studio, plan: plan, starter: focus)
            Divider()
            GuidedPicksTray(
                picks: picks,
                text: picks.isEmpty
                    ? String(localized: "Nothing picked yet. Preview a template above, then Add to My Picks.")
                    : trayText,
                emptyHeight: 88,
                identifier: "autopilot.guided.look.template.tray",
                name: \.title,
                preview: { studio.guided.templateFocus = $0 },
                remove: { studio.toggleShotTemplate($0) },
                thumbnail: { starter in
                    HStack(spacing: 3) {
                        ForEach(Array(studio.screenshots.starterImages(starter).prefix(3).enumerated()), id: \.offset) { _, image in
                            StudioShotImage(image: image, width: 34, aspect: GuidedTemplateFocus.aspect)
                        }
                    }
                }
            )
        }
        .modifier(GuidedSelectableCard(padding: 0))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .task { await studio.screenshots.renderStarterPreviews() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.look.templateBrowser")
    }

    /// "Claude Design makes one look from each pick, in Northpier Brand.
    /// You choose one after it’s made."
    private var trayText: String {
        let designer = studio.shotStyleDesigner
        guard let brand = studio.shotStyleBrand else {
            return String(localized: "\(designer) makes one look from each pick. You choose one after it’s made.")
        }
        return String(localized: "\(designer) makes one look from each pick, in \(brand). You choose one after it’s made.")
    }

    private func thumbnail(_ starter: TemplateStarter, isFocused: Bool) -> some View {
        let number = studio.shotTemplateNumber(starter)
        let isInUse = studio.screenshots.document?.template?.starter == starter
        return Button {
            studio.guided.templateFocus = starter
        } label: {
            VStack(spacing: Spacing.xxSmall) {
                StudioShotImage(image: studio.screenshots.starterImages(starter).first ?? nil, width: 48, aspect: GuidedTemplateFocus.aspect)
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
                Text(starter.title)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 24, alignment: .top)
                if isInUse {
                    Text("In use now").font(.system(size: 9.5)).foregroundStyle(Palette.label2)
                }
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(isFocused ? Palette.accentTint : Color.clear, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(number != nil ? Palette.accent : Color.clear, lineWidth: 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(thumbnailLabel(starter, number: number, isInUse: isInUse)))
        .accessibilityAddTraits(isFocused ? .isSelected : [])
        .accessibilityIdentifier("autopilot.guided.look.template.\(starter.rawValue)")
    }

    /// "Cinema, pick 2, in use now".
    private func thumbnailLabel(_ starter: TemplateStarter, number: Int?, isInUse: Bool) -> String {
        var parts = [starter.title]
        if let number { parts.append(String(localized: "pick \(number)")) }
        if isInUse { parts.append(String(localized: "in use now")) }
        return parts.joined(separator: ", ")
    }
}
