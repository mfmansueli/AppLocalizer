//
//  GuidedOptionCard.swift
//  AppLocalizer
//

import SwiftUI

/// One of the Look step's choices (a new look, templates, the current
/// look; scene templates or going freely): an optional preview, its
/// title, "In use now" when it is, and what it means. Chosen, it has the
/// accent's outline.
struct GuidedOptionCard<Preview: View>: View {
    let title: String
    let text: String
    let isSelected: Bool
    var isInUse = false
    var isEnabled = true
    let identifier: String
    let action: () -> Void
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                preview()
                HStack(spacing: Spacing.xSmall) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(isEnabled ? Palette.label : Palette.label3)
                    if isInUse {
                        Pill(text: String(localized: "In use now"), style: .neutral)
                    }
                }
                Text(text)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .modifier(GuidedSelectableCard(isSelected: isSelected, padding: 10))
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}

extension GuidedOptionCard where Preview == EmptyView {
    init(
        title: String, text: String, isSelected: Bool, isInUse: Bool = false, isEnabled: Bool = true,
        identifier: String, action: @escaping () -> Void
    ) {
        self.init(
            title: title, text: text, isSelected: isSelected, isInUse: isInUse, isEnabled: isEnabled,
            identifier: identifier, action: action
        ) { EmptyView() }
    }
}
