//
//  AutopilotHeaderTemplateTile.swift
//  AppLocalizer
//

import SwiftUI

/// One scene template on the plan: its preview in the app's colors (moving
/// with Motion loop), its pick number, Recommended, its name, what it is
/// and what it fits, and its loop.
struct AutopilotHeaderTemplateTile: View {
    let template: AutopilotHeaderTemplate
    /// 1, 2, 3 when picked.
    let number: Int?
    let isRecommended: Bool
    let isMoving: Bool
    let colors: (light: Color, dark: Color)
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { proxy in
                    HeaderTemplateSketch(template: template, light: colors.light, dark: colors.dark, isMoving: isMoving, width: proxy.size.width)
                        .overlay(alignment: .topTrailing) {
                            if let number {
                                Text(number.formatted())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 18, height: 18)
                                    .background(Circle().fill(Palette.accent))
                                    .padding(5)
                            }
                        }
                        .overlay(alignment: .topLeading) {
                            if isRecommended {
                                Text("Recommended")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Palette.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Palette.raised))
                                    .padding(5)
                            }
                        }
                }
                .aspectRatio(CGFloat(AutopilotArtworkKind.header.pixelSize.width) / CGFloat(AutopilotArtworkKind.header.pixelSize.height), contentMode: .fit)
                Text(template.name)
                    .font(.callout.weight(.semibold))
                Text(template.tileDetail)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                if isMoving {
                    Text(template.loopLine)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Palette.raised))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(number == nil ? Palette.separator : Palette.accent, lineWidth: number == nil ? 0.5 : 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(number == nil ? String(localized: "Add \(template.name)") : String(localized: "Remove \(template.name)")))
        .accessibilityValue(Text(number.map { String(localized: "Pick \($0)") } ?? ""))
        .accessibilityAddTraits(number == nil ? [] : .isSelected)
        .accessibilityIdentifier("autopilot.plan.headerTemplate.\(template.rawValue)")
    }
}
