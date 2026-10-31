//
//  ScreenshotRestoreStage.swift
//  AppLocalizer
//

import SwiftUI

/// The restore sheet's right side: iPhone 6.9″ | iPad 13″, the kept set on
/// a stage, and what restoring does, or that the locale had none.
struct ScreenshotRestoreStage: View {
    let choice: ScreenshotRestoreChoice
    let backupDate: Date
    @Binding var displayType: ScreenshotDisplayType
    let thumbnails: [String: CGImage]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Picker("Display type", selection: $displayType) {
                ForEach(ScreenshotDisplayType.studio.filter { $0.isRendered || !choice.images(on: $0).isEmpty }) { display in
                    Text(display.title).tag(display)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .accessibilityIdentifier("restore.displayType")
            Text("KEPT ON THIS MAC · \(backupDate.formatted(.dateTime.month(.abbreviated).day().year()))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.label2)
            stage
            if choice.hasImages {
                Text("Restoring takes \(choice.locale.name) out of re-rendering until you choose Use Template Again, so the next push doesn’t replace these again.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stage: some View {
        Group {
            let images = choice.images(on: displayType)
            if images.isEmpty {
                Text(emptyText)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .padding(Spacing.xLarge)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("restore.none")
            } else {
                FlowLayout(spacing: Spacing.small, lineSpacing: Spacing.small) {
                    ForEach(images) { image in
                        ScreenshotThumbnail(image: thumbnails[image.id], width: width, aspect: aspect(image), isLoading: true)
                            .accessibilityLabel(Text("Kept screenshot \(image.position + 1)"))
                    }
                }
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Palette.stage, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("restore.stage")
    }

    private var width: CGFloat { displayType.isTablet ? 120 : 70 }

    private func aspect(_ image: ScreenshotBackupImage) -> CGFloat {
        let size = image.pixelSize ?? image.displayType.portraitPixelSize
        return size.width > 0 ? CGFloat(size.height) / CGFloat(size.width) : 2
    }

    private var emptyText: String {
        guard choice.hasImages else {
            return String(localized: "\(choice.locale.name) had no screenshots of its own then. To go back to that, take it out of the localized locales; nothing live is deleted.")
        }
        return String(localized: "Nothing was kept for \(displayType.title).")
    }
}
