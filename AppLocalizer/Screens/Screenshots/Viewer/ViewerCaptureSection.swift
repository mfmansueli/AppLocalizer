//
//  ViewerCaptureSection.swift
//  AppLocalizer
//

import SwiftUI

/// The capture a render is made from: its file, pixel size, source and
/// whether it shows the locale's own interface.
struct ViewerCaptureSection: View {
    let cell: ScreenshotCell
    let primaryName: String

    var body: some View {
        ViewerSection(title: String(localized: "Capture")) {
            if let resolved = cell.capture {
                Text(resolved.capture.fileName)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .lineLimit(2)
                Text(details(resolved))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let live = cell.live {
                Text("Live in App Store Connect")
                    .font(.callout)
                Text(verbatim: live.fileName)
                    .font(.caption.monospaced())
                    .foregroundStyle(Palette.label2)
            } else {
                Text("No capture for this slot yet.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
        }
    }

    /// "1320 × 2868 · fastlane snapshot · localized interface".
    private func details(_ resolved: ResolvedCapture) -> String {
        let interface = resolved.isInterfaceLocalized
            ? String(localized: "localized interface")
            : String(localized: "\(primaryName) interface, not localized")
        return [resolved.capture.pixelSize.title, resolved.capture.source.title, interface].joined(separator: " · ")
    }
}
