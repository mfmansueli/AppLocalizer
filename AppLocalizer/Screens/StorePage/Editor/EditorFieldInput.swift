//
//  EditorFieldInput.swift
//  AppLocalizer
//

import SwiftUI

/// The edited locale's text for one field: a text field, or a text area for
/// Description and What's New. Right-to-left locales lay it out from the
/// right; URLs always stay left to right. Over the limit or an invalid URL
/// draws a red outline.
struct EditorFieldInput: View {
    let field: ListingField
    let locale: StoreLocale
    @Binding var text: String
    let isEditable: Bool
    let isBlocked: Bool

    var body: some View {
        Group {
            if field.isMultiline {
                TextEditor(text: $text)
                    .font(.callout)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, Spacing.xxSmall)
                    .padding(.vertical, Spacing.xxSmall)
                    .frame(height: field == .description ? 130 : 90)
                    .background(Palette.content, in: shape)
                    .overlay(shape.strokeBorder(isBlocked ? Palette.danger : Palette.separator2, lineWidth: isBlocked ? 1.5 : 1))
            } else {
                TextField(text: $text, prompt: Text(field.isURL ? "https://" : "")) {
                    Text(field.title)
                }
                .textFieldStyle(.roundedBorder)
                .font(.callout)
                .overlay {
                    if isBlocked {
                        shape.strokeBorder(Palette.danger, lineWidth: 1.5)
                    }
                }
            }
        }
        .disabled(!isEditable)
        .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
        .accessibilityLabel(Text("\(locale.name), \(field.title)"))
        .accessibilityIdentifier("storePage.input.\(field.rawValue)")
    }

    private var isRightToLeft: Bool { locale.isRTL && !field.isURL }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
    }
}
