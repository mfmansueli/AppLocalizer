//
//  RetentionTextFields.swift
//  AppLocalizer
//

import SwiftUI

/// The selected language's header (66) and message (144), each with a
/// live counter that turns red past Apple's limit. Arabic and Hebrew run
/// right to left.
struct RetentionTextFields: View {
    let model: RetentionModel

    var body: some View {
        let text = model.selectedText
        let direction: LayoutDirection = RetentionCancelStrings.isRightToLeft(model.selectedLocale) ? .rightToLeft : .leftToRight
        VStack(alignment: .leading, spacing: Spacing.small) {
            label(String(localized: "Header"), count: text.headerCount, limit: RetentionLimits.headerLength, identifier: "retention.headerCount")
            TextField("Header", text: Binding(get: { model.selectedText.header }, set: model.setHeader), prompt: Text("What they keep, in a few words"))
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .environment(\.layoutDirection, direction)
                .accessibilityLabel("Header")
                .accessibilityIdentifier("retention.header")
            label(String(localized: "Message"), count: text.bodyCount, limit: RetentionLimits.bodyLength, identifier: "retention.bodyCount")
            TextEditor(text: Binding(get: { model.selectedText.body }, set: model.setBody))
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(Spacing.xxSmall)
                .frame(height: 64)
                .background(Palette.content, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                        .strokeBorder(Palette.separator2, lineWidth: 0.5)
                }
                .environment(\.layoutDirection, direction)
                .accessibilityLabel("Message")
                .accessibilityIdentifier("retention.body")
        }
        .disabled(model.isTranslating)
    }

    private func label(_ title: String, count: Int, limit: Int, identifier: String) -> some View {
        HStack {
            Text(title)
                .font(.callout.weight(.medium))
            Spacer()
            Text("\(count) / \(limit)")
                .font(.caption.weight(count > limit ? .bold : .regular))
                .foregroundStyle(count > limit ? Palette.danger : Palette.label2)
                .monospacedDigit()
                .accessibilityLabel(Text("\(count) of \(limit) characters"))
                .accessibilityIdentifier(identifier)
        }
    }
}
