//
//  WorkspaceSectionPicker.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// The toolbar's section picker, with a badge on the sections that have
/// suggestions to review.
struct WorkspaceSectionPicker: View {
    let counts: SectionBadgeCounts
    @Binding var selection: AppWorkspaceSection

    private static let sections = AppWorkspaceSection.allCases
    private static let labelFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    private static let badgeFont = NSFont.systemFont(ofSize: SectionBadgePill.fontSize, weight: .semibold)

    private var layout: SegmentBadgeLayout {
        SegmentBadgeLayout(
            titles: Self.sections.map(\.title),
            badgeWidths: Self.sections.map { section in
                counts.text(for: section).map { SectionBadgePill.width(textWidth: Self.width(of: $0, in: Self.badgeFont)) }
            },
            measure: { Self.width(of: $0, in: Self.labelFont) }
        )
    }

    var body: some View {
        let layout = layout
        FittingSegmentedPicker(
            label: String(localized: "Section"),
            options: Array(zip(Self.sections, layout.labels)).map { (value: $0, title: $1) },
            selection: $selection
        )
        .fixedSize()
        .accessibilityIdentifier("workspace.sectionPicker")
        .overlay {
            GeometryReader { proxy in
                ForEach(Array(Self.sections.enumerated()), id: \.element) { index, section in
                    if let text = counts.text(for: section), let x = layout.badgeCenterX(at: index, totalWidth: proxy.size.width) {
                        SectionBadgePill(text: text, width: layout.badgeWidths[index] ?? 0)
                            .position(x: x, y: proxy.size.height / 2)
                    }
                }
                .accessibilityHidden(true)
                // One element for every count, always there: separate
                // labels on the pills read another pill's after the picker
                // lost its badges and got them back.
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityElement()
                    .accessibilityLabel(Text(counts.accessibilitySummary))
                    .accessibilityIdentifier("workspace.sectionBadges")
            }
            // Clicks go through to the segment under the badge.
            .allowsHitTesting(false)
        }
    }

    private static func width(of text: String, in font: NSFont) -> CGFloat {
        ceil(NSAttributedString(string: text, attributes: [.font: font]).size().width)
    }
}

#Preview {
    @Previewable @State var selection = AppWorkspaceSection.storePage
    WorkspaceSectionPicker(counts: SectionBadgeCounts([.storePage: 28, .appInformation: 120]), selection: $selection)
        .padding()
}
