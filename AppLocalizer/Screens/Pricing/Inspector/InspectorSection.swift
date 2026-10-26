//
//  InspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// A collapsible inspector section: an uppercase title with a chevron, an
/// optional trailing control, then its content. Collapsing is remembered
/// in the strategy model.
struct InspectorSection<Trailing: View, Content: View>: View {
    let section: StrategyInspectorSection
    let model: PricingStrategyModel
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var content: () -> Content

    init(
        _ section: StrategyInspectorSection,
        in model: PricingStrategyModel,
        @ViewBuilder trailing: @escaping () -> Trailing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.section = section
        self.model = model
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        let title = section.title
        let isCollapsed = model.isCollapsed(section)
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.xSmall) {
                Button(action: toggle) {
                    HStack {
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(Palette.label2)
                        Spacer(minLength: Spacing.small)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityValue(isCollapsed ? String(localized: "Collapsed") : String(localized: "Expanded"))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("pricing.inspector.section.\(section.rawValue)")
                trailing()
                Button(action: toggle) {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.label2)
                        .frame(width: 16, height: 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isCollapsed ? String(localized: "Expand \(title)") : String(localized: "Collapse \(title)"))
            }
            if !isCollapsed {
                content()
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .contain)
    }

    private func toggle() {
        model.toggle(section)
    }
}
