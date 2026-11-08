//
//  CaptionFields.swift
//  AppLocalizer
//

import SwiftUI

/// The kicker line where the template sets one, the headline and, on hero
/// slots, the subhead, in the locale's reading direction. The headline's
/// edge turns red while it overflows.
struct CaptionFields: View {
    let model: CaptionsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            if model.showsKickerField {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("\(Text("Kicker").fontWeight(.semibold)) \(Text("· the line over the headline").foregroundStyle(Palette.label2))")
                        .font(.callout)
                    field(
                        Binding { model.kicker } set: { model.setKicker($0) },
                        prompt: String(localized: "Optional: empty shows the headline alone"), isOverflowing: false
                    )
                    .accessibilityLabel(Text("Kicker"))
                    .accessibilityIdentifier("screenshots.captions.editor.kicker")
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Headline")
                    .font(.callout.weight(.semibold))
                field(
                    Binding { model.headline } set: { model.setHeadline($0) },
                    prompt: model.headlinePlaceholder,
                    isOverflowing: model.editorPreview?.fit.tone == .overflows
                )
                .accessibilityLabel(Text("Headline"))
                .accessibilityIdentifier("screenshots.captions.editor.headline")
            }
            if model.showsSubheadField {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("\(Text("Subhead").fontWeight(.semibold)) \(Text("· slot 1 only").foregroundStyle(Palette.label2))")
                        .font(.callout)
                    field(Binding { model.subhead } set: { model.setSubhead($0) }, prompt: String(localized: "Optional"), isOverflowing: false)
                        .accessibilityLabel(Text("Subhead"))
                        .accessibilityIdentifier("screenshots.captions.editor.subhead")
                }
            }
        }
    }

    private func field(_ text: Binding<String>, prompt: String, isOverflowing: Bool) -> some View {
        TextField("", text: text, prompt: Text(prompt), axis: .vertical)
            .lineLimit(2...4)
            .textFieldStyle(.plain)
            .font(.body)
            .multilineTextAlignment(.leading)
            .padding(Spacing.small)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.field))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.field)
                    .strokeBorder(isOverflowing ? Palette.dangerMark : Palette.separator2, lineWidth: isOverflowing ? 1.5 : 0.5)
            )
            .environment(\.layoutDirection, model.isRightToLeft ? .rightToLeft : .leftToRight)
    }
}
