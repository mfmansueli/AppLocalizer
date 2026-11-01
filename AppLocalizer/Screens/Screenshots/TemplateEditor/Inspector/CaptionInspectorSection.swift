//
//  CaptionInspectorSection.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// Placement, alignment, headline font (with uploaded and bundled fonts),
/// size in u, color, and the headline's uppercase, emphasis and highlight.
struct CaptionInspectorSection: View {
    let model: TemplateEditorViewModel
    @State private var isImporting = false

    private static let note = String(localized: """
    Emphasis and highlights apply per line after wrapping, so they follow every language’s line breaks. \
    1 u is 1/1320 of the canvas’s short side.
    """)

    var body: some View {
        if let caption = model.template?.caption {
            TemplateInspectorSection(title: String(localized: "Caption")) {
                TemplateInspectorRow(label: String(localized: "Placement")) {
                    Picker("Placement", selection: Binding { caption.placement } set: { model.set("caption.placement", to: .string($0.rawValue)) }) {
                        Text("Above").tag(TemplateCaption.Placement.above)
                        Text("Below").tag(TemplateCaption.Placement.below)
                        Text("Band").tag(TemplateCaption.Placement.band)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    .accessibilityIdentifier("screenshots.template.placement")
                }
                TemplateInspectorRow(label: String(localized: "Alignment")) {
                    Picker("Alignment", selection: Binding { caption.align } set: { model.set("caption.align", to: .string($0.rawValue)) }) {
                        Text("Center").tag(TemplateCaption.Alignment.center)
                        Text("Start").tag(TemplateCaption.Alignment.start)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                }
                TemplateInspectorRow(label: String(localized: "Headline font")) {
                    Picker("Headline font", selection: Binding { caption.headline.font } set: { model.setDisplayFont($0) }) {
                        ForEach(model.displayFontOptions, id: \.self) { font in
                            Text(model.fontTitle(font)).tag(font)
                        }
                    }
                    .labelsHidden()
                    .accessibilityIdentifier("screenshots.template.font")
                }
                Button("Upload Font…") { isImporting = true }
                    .buttonStyle(.link)
                    .font(.caption)
                    .padding(.leading, 100)
                    .accessibilityIdentifier("screenshots.template.uploadFont")
                TemplateInspectorSlider(label: String(localized: "Size"), value: caption.headline.size, range: 72...140, step: 2, unit: " u") {
                    model.setHeadlineSize($0)
                }
                .accessibilityIdentifier("screenshots.template.size")
                TemplateInspectorRow(label: String(localized: "Color")) {
                    TemplateInspectorColorWell(label: String(localized: "Caption color"), color: model.slotInk) {
                        model.setInk($0)
                    }
                }
                CaptionLookInspectorRows(model: model)
                Text(Self.note)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .layoutPriority(1)
            }
            .controlSize(.small)
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.font]) { result in
                guard case let .success(url) = result else { return }
                Task {
                    let isScoped = url.startAccessingSecurityScopedResource()
                    defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
                    await model.uploadFont(from: url)
                }
            }
        }
    }
}
