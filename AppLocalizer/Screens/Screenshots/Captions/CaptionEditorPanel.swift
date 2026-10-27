//
//  CaptionEditorPanel.swift
//  AppLocalizer
//

import SwiftUI

/// The selected caption: the English source, headline and subhead fields
/// in the locale's reading direction, the live fit, a preview with the
/// caption box, Mark Reviewed and "Suggest a Shorter Version".
struct CaptionEditorPanel: View {
    let model: CaptionsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                header
                if let source = model.sourceHeadline {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.screenshots.context.primaryLocale.name)
                            .textCase(.uppercase)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Palette.label2)
                        Text(source)
                            .font(.callout)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.xSmall)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.field))
                    .overlay(RoundedRectangle(cornerRadius: Radius.field).strokeBorder(Palette.separator, lineWidth: 0.5))
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("screenshots.captions.editor.source")
                }
                CaptionFields(model: model)
                CaptionFitSection(model: model)
                preview
                CaptionEditorTags(model: model)
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
        }
        .background(Palette.content)
        .task(id: model.selection) { model.loadPreviewCapture() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Caption editor"))
        .accessibilityIdentifier("screenshots.captions.editor")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.editorTitle)
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("screenshots.captions.editor.title")
                Text(model.editorSubtitle)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
            Spacer(minLength: 0)
            Button {
                model.close()
            } label: {
                Image(systemName: "xmark")
            }
            .controlSize(.small)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel(Text("Close editor"))
            .accessibilityIdentifier("screenshots.captions.editor.close")
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let preview = model.editorPreview {
            SlotPreviewImage(preview: preview, capture: model.previewCapture(for: preview), width: model.previewWidth, showsGuides: true)
                .frame(maxWidth: .infinity)
                .padding(Spacing.small)
                .background(Palette.stage, in: RoundedRectangle(cornerRadius: Radius.banner))
                .accessibilityElement()
                .accessibilityLabel(Text("Preview"))
                .accessibilityIdentifier("screenshots.captions.editor.preview")
        }
    }
}
