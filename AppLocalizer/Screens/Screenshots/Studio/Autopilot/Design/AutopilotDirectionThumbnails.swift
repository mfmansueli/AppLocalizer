//
//  AutopilotDirectionThumbnails.swift
//  AppLocalizer
//

import SwiftUI

/// A direction's five screenshots, side by side, with the picks.
struct AutopilotDirectionThumbnails: View {
    @Bindable var studio: ScreenshotStudioModel
    let direction: AutopilotDirection
    var width: CGFloat = 58
    /// Apple Vision Pro and Apple Watch go on a line of their own when the
    /// row is too narrow for them beside the set.
    var stacksDevices = false

    var body: some View {
        let layouts = studio.layouts(for: direction)
        let captures = studio.pickedCaptures
        let vision = studio.visionPreview(for: direction)
        let watch = studio.watchPreviewCapture
        let layout = stacksDevices ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xSmall)) : AnyLayout(HStackLayout(spacing: Spacing.xSmall))
        layout {
            HStack(spacing: Spacing.xxSmall) {
                ForEach(layouts.indices, id: \.self) { slot in
                    let capture = captures.indices.contains(slot) ? captures[slot] : nil
                    AutopilotLayoutImage(layout: layouts[slot], capture: studio.image(for: capture, width: 240), width: width)
                }
            }
            if vision != nil || watch != nil {
                HStack(alignment: .center, spacing: Spacing.xSmall) {
                    if let vision {
                        AutopilotLayoutImage(layout: vision.layout, capture: studio.image(for: vision.capture, width: 480), width: width * 2)
                    }
                    if let watch {
                        StudioShotImage(
                            image: studio.image(for: watch, width: 160), width: width * 0.8,
                            aspect: Double(watch.pixelSize.height) / Double(max(watch.pixelSize.width, 1)), cornerFraction: 0.24
                        )
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText(screens: layouts.count, vision: vision != nil, watch: watch != nil)))
        .accessibilityIdentifier("autopilot.direction.thumbnails")
    }

    /// The width of the set, Apple Vision Pro and Apple Watch side by side.
    static func oneRowWidth(thumbnail: CGFloat, screens: Int, hasVision: Bool, hasWatch: Bool) -> CGFloat {
        var width = thumbnail * CGFloat(screens) + Spacing.xxSmall * CGFloat(max(screens - 1, 0))
        if hasVision { width += Spacing.xSmall + thumbnail * 2 }
        if hasWatch { width += Spacing.xSmall + thumbnail * 0.8 }
        return width
    }

    private func accessibilityText(screens: Int, vision: Bool, watch: Bool) -> String {
        var parts = [String(localized: "\(screens) screenshots in \(direction.name)")]
        if vision { parts.append(String(localized: "an Apple Vision Pro screenshot")) }
        if watch { parts.append(String(localized: "an Apple Watch capture")) }
        return parts.formatted(.list(type: .and))
    }
}
