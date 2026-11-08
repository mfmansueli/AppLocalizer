//
//  DecorationInspectorRow.swift
//  AppLocalizer
//

import SwiftUI

/// One decoration on the slot: its name, its color (not on a multi-color
/// prop), Hide or Show, and Remove; under them, the App Store rating a
/// laurel shows with Type It, or the value typed (with Use App Store on a
/// laurel). A hidden one is dimmed. Two lines, so the inspector never
/// grows wider than its column.
struct DecorationInspectorRow: View {
    let model: TemplateEditorViewModel
    let decoration: TemplateDecoration
    let index: Int
    @State private var value = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            HStack(spacing: Spacing.xSmall) {
                Text(model.decorationTitle(decoration))
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(decoration.isHidden ? 0.5 : 1)
                if decoration.takesColor {
                    TemplateInspectorColorWell(label: String(localized: "\(decoration.title) color"), color: decoration.color, showsHex: false) {
                        model.setDecorationColor($0, at: index)
                    }
                }
                Button(decoration.isHidden ? String(localized: "Show") : String(localized: "Hide")) { model.toggleDecorationHidden(at: index) }
                    .buttonStyle(.link)
                    .font(.caption)
                    .accessibilityLabel(decoration.isHidden ? Text("Show \(decoration.title)") : Text("Hide \(decoration.title)"))
                    .accessibilityIdentifier("screenshots.template.hideDecoration.\(index)")
                Button("Remove") { model.removeDecoration(at: index) }
                    .buttonStyle(.link)
                    .font(.caption)
                    .accessibilityLabel(Text("Remove \(decoration.title)"))
                    .accessibilityIdentifier("screenshots.template.removeDecoration.\(index)")
            }
            rating
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.template.decoration.\(index)")
        .onAppear { value = decoration.value ?? "" }
        .onChange(of: decoration.value) { _, newValue in value = newValue ?? "" }
    }

    /// The App Store rating with Type It, or the value typed.
    @ViewBuilder
    private var rating: some View {
        if decoration.showsStoreRating {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                Text(model.storeRatingLine)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .help(Text("From the App Store, per country, refreshed daily"))
                    .accessibilityIdentifier("screenshots.template.storeRating.\(index)")
                Button("Type It") { model.typeRating(at: index) }
                    .buttonStyle(.link)
                    .font(.caption)
                    .accessibilityIdentifier("screenshots.template.typeRating.\(index)")
            }
        } else if decoration.isRating {
            HStack(spacing: Spacing.xSmall) {
                TextField("Value", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 58)
                    .onSubmit { model.setDecorationValue(value, at: index) }
                    .accessibilityLabel(Text("Value shown on the \(decoration.title)"))
                    .accessibilityIdentifier("screenshots.template.decorationValue.\(index)")
                if decoration.type == .laurel {
                    Button("Use App Store") { model.useStoreRating(at: index) }
                        .buttonStyle(.link)
                        .font(.caption)
                        .accessibilityIdentifier("screenshots.template.useStoreRating.\(index)")
                }
            }
        }
    }
}
