//
//  TemplateStyleFilter.swift
//  AppLocalizer
//

import SwiftUI

/// All, Simple, Bold, Elegant, Playful: which templates the gallery shows.
struct TemplateStyleFilter: View {
    @Binding var style: TemplateStarter.Style?

    var body: some View {
        Picker("Template style", selection: $style) {
            Text("All").tag(TemplateStarter.Style?.none)
            ForEach(TemplateStarter.Style.allCases) { style in
                Text(style.title).tag(Optional(style))
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .controlSize(.small)
        .accessibilityIdentifier("screenshots.gallery.style")
    }
}
