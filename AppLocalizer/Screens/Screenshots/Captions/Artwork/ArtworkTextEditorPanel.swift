//
//  ArtworkTextEditorPanel.swift
//  AppLocalizer
//

import SwiftUI

/// Beside Captions for a Search results or Header cell: what the text is
/// for, the headline, its fit on the artwork and its words, and for the
/// search headline the language's subtitle and keywords to start from.
struct ArtworkTextEditorPanel: View {
    let editor: ArtworkTextEditor

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                header
                Text(editor.guidance)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("screenshots.captions.artworkEditor.guidance")
                field
                fitSection
                if !editor.sources.isEmpty { sources }
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
        }
        .background(Palette.content)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Artwork text editor"))
        .accessibilityIdentifier("screenshots.captions.artworkEditor")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Text(editor.title)
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier("screenshots.captions.artworkEditor.title")
            Spacer(minLength: 0)
            Button {
                editor.close()
            } label: {
                Image(systemName: "xmark")
            }
            .controlSize(.small)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel(Text("Close editor"))
            .accessibilityIdentifier("screenshots.captions.artworkEditor.close")
        }
    }

    private var field: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(editor.isPhrase ? String(localized: "Words") : String(localized: "Headline"))
                .font(.callout.weight(.semibold))
            TextField(
                "", text: Binding { editor.headline } set: { editor.setHeadline($0) },
                prompt: Text(editor.prompt),
                axis: .vertical
            )
            .lineLimit(1...3)
            .textFieldStyle(.plain)
            .font(.body)
            .padding(Spacing.small)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.field))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.field)
                    .strokeBorder(
                        editor.fit?.tone == .overflows ? Palette.dangerMark : Palette.separator2,
                        lineWidth: editor.fit?.tone == .overflows ? 1.5 : 0.5
                    )
            )
            .environment(\.layoutDirection, editor.isRightToLeft ? .rightToLeft : .leftToRight)
            .accessibilityLabel(Text(editor.isPhrase ? String(localized: "Words") : String(localized: "Headline")))
            .accessibilityIdentifier("screenshots.captions.artworkEditor.headline")
        }
    }

    private var fitSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Fit")
                .font(.callout.weight(.semibold))
            if let fit = editor.fit {
                FitMeter(value: FitMeterValue(fit: fit), height: 7)
                    .padding(.vertical, 2)
                Text(ArtworkTextCell.label(fit))
                    .font(.callout.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(fit.tone == .overflows ? Palette.danger : fit.tone == .shrinks ? Palette.warning : Palette.label)
                    .accessibilityIdentifier("screenshots.captions.artworkEditor.fitLabel")
            }
            if let detail = editor.countDetail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(editor.count?.isTooLong == true ? Palette.warning : Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("screenshots.captions.artworkEditor.count")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Start from")
                .font(.callout.weight(.semibold))
            ForEach(editor.sources, id: \.title) { source in
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.title)
                        .textCase(.uppercase)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.label2)
                    Text(source.text)
                        .font(.callout)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    if source.title == String(localized: "Subtitle") {
                        Button("Use Subtitle") { editor.use(source.text) }
                            .buttonStyle(.link)
                            .accessibilityIdentifier("screenshots.captions.artworkEditor.useSubtitle")
                    }
                }
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, Spacing.xSmall)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.field))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.captions.artworkEditor.sources")
    }
}
