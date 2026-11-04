//
//  AutopilotHeaderStyleBox.swift
//  AppLocalizer
//

import SwiftUI

/// Header style, in the plan's Header and search row: start from scene
/// templates (six previews in the app's colors, up to three picked, the
/// recommended one marked, with why) or let the design AI go freely (what
/// it gets from the scan).
struct AutopilotHeaderStyleBox: View {
    @Bindable var studio: ScreenshotStudioModel
    let extras: AutopilotExtras

    private let columns = Array(repeating: GridItem(.flexible(minimum: 0), spacing: Spacing.small, alignment: .top), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .center, spacing: Spacing.small) {
                Text("Header style")
                    .font(.callout.weight(.semibold))
                StudioSegmentedControl(
                    label: String(localized: "Header style"),
                    options: AutopilotArtworkStyle.allCases.map { .init(value: $0, title: $0.title, key: $0.rawValue) },
                    selection: Binding { extras.artworkStyle } set: { studio.setArtworkStyle($0) },
                    identifier: "autopilot.plan.headerStyle"
                )
                .fixedSize()
                if extras.artworkStyle == .templates {
                    Text(studio.headerTemplatesNote)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("autopilot.plan.headerStyle.note")
                }
            }
            switch extras.artworkStyle {
            case .templates: templates
            case .free: free
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, Spacing.small)
        .background(Palette.content, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .task { await studio.loadHeaderColors() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.headerStyleBox")
    }

    private var templates: some View {
        let picks = studio.headerTemplatePicks
        let recommendation = studio.headerRecommendation
        let colors = studio.headerSketchColors
        return VStack(alignment: .leading, spacing: Spacing.small) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.small) {
                ForEach(AutopilotHeaderTemplate.allCases) { template in
                    AutopilotHeaderTemplateTile(
                        template: template, number: picks.firstIndex(of: template).map { $0 + 1 },
                        isRecommended: template == recommendation.template, isMoving: extras.makesMotion, colors: colors
                    ) {
                        studio.toggleHeaderTemplate(template)
                    }
                }
            }
            Text(recommendation.text(appName: studio.app.name))
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("autopilot.plan.headerStyle.recommendation")
        }
    }

    private var free: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(studio.headerFreeText)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("autopilot.plan.headerStyle.freeText")
            VStack(alignment: .leading, spacing: 0) {
                Text("What \(studio.headerDesignerName) gets from the scan")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.fill1)
                ForEach(Array(studio.headerScanRows.enumerated()), id: \.offset) { index, row in
                    if index > 0 { Divider() }
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(row.key)
                            .font(.caption.weight(.semibold))
                            .frame(width: 96, alignment: .leading)
                        Text(row.value)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .accessibilityElement(children: .combine)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("autopilot.plan.headerStyle.scan")
        }
    }
}
