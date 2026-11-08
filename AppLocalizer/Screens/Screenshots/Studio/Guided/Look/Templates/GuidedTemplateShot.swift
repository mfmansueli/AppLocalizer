//
//  GuidedTemplateShot.swift
//  AppLocalizer
//

import SwiftUI

/// One screenshot of the previewed template, its screen's name under it;
/// a click shows it larger in the viewer.
struct GuidedTemplateShot: View {
    let studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    let preview: GuidedTemplatePreview
    let item: GuidedTemplatePreviewItem
    let width: CGFloat

    var body: some View {
        VStack(spacing: Spacing.xxSmall) {
            Button {
                studio.openTemplatePreview(preview.starter, plan: plan, at: item.slot)
            } label: {
                GuidedJobImage(studio: studio, job: item.job, width: width, cornerFraction: preview.isWatch ? 0.24 : 0.05)
                    .shadow(color: .black.opacity(0.14), radius: 5, y: 2)
                    .overlay(alignment: .bottomLeading) {
                        if item.showsPrimaryInterface { interfaceMark }
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(Text("See it larger"))
            .accessibilityLabel(Text(accessibilityText))
            .accessibilityIdentifier("autopilot.guided.look.template.shot.\(item.slot)")
            Text(item.label)
                .font(.caption2)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .frame(maxWidth: width)
        }
    }

    /// "Arcade · iPhone · Arabic · 3 of 5: Search. Click to see it larger",
    /// and "English interface" where the language isn't captured yet.
    private var accessibilityText: String {
        let place = [preview.starter.title, GuidedTemplatePreviewDevices.title(preview.device), preview.locale.shortName].joined(separator: " · ")
        let text = String(localized: "\(place) · \(item.slot + 1) of \(preview.items.count): \(item.name). Click to see it larger")
        guard item.showsPrimaryInterface else { return text }
        return text + ". " + String(localized: "\(primaryName) interface, not captured in this language yet")
    }

    private var primaryName: String {
        StoreLocaleCatalog.locale(code: plan.primaryLocale)?.shortName ?? plan.primaryLocale
    }

    /// "English UI" on a screenshot whose capture is the primary
    /// language's interface: the device isn't captured in this one yet.
    /// The captures' "UI" chip colors (`InterfaceChip`), which read better
    /// than white on orange.
    private var interfaceMark: some View {
        Text("\(primaryName) UI")
            .font(.system(size: 9.5, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.85))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Palette.warningMark, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .padding(4)
            .accessibilityHidden(true)
    }

    /// The width a screenshot shows at on `device`: five fit across the
    /// sheet, three Apple Vision Pro windows.
    static func width(for item: GuidedTemplatePreviewItem, on device: ScreenshotDisplayType) -> CGFloat {
        switch device {
        case .watch: 112
        case .visionPro: 268
        case .mac: 180
        default: item.aspect < 1 ? 160 : item.aspect > 1.8 ? 124 : 112
        }
    }
}
