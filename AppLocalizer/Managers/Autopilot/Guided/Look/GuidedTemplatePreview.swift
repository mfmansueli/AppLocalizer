//
//  GuidedTemplatePreview.swift
//  AppLocalizer
//

import Foundation

/// A gallery template previewed on one device in one language: its
/// screenshots drawn by the real layout engine with the app's captions and
/// captures, the device's size, whether the run makes it, and what's worth
/// knowing about it there.
struct GuidedTemplatePreview: Hashable {
    var starter: TemplateStarter
    /// iPhone, iPad, iPhone Duo, Mac, Apple Vision Pro or Apple Watch.
    var device: ScreenshotDisplayType
    var locale: StoreLocale
    var items: [GuidedTemplatePreviewItem]
    /// "iPhone 6.9″ · 1320 × 2868", "Mac · 2880 × 1800".
    var sizeTitle: String
    /// "The App Store scales this set down for smaller iPhones, so one size
    /// covers them all."
    var note: String
    /// The run makes this device's screenshots; the others are only a
    /// preview until they're added.
    var isInRun = true

    /// Apple shows watch screens bare: no template applies.
    var isWatch: Bool { device == .watch }

    /// "Mac isn’t in this run yet, so this is only a preview. Add it and
    /// Autopilot captures and makes these screenshots too."
    var notInRunText: String {
        let title = GuidedTemplatePreviewDevices.title(device)
        return String(localized: "\(title) isn’t in this run yet, so this is only a preview. Add it and Autopilot captures and makes these screenshots too.")
    }

    /// "Add Mac to the Run".
    var addTitle: String {
        String(localized: "Add \(GuidedTemplatePreviewDevices.title(device)) to the Run")
    }
}
