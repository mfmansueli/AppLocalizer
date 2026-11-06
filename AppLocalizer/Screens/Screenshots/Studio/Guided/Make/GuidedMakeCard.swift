//
//  GuidedMakeCard.swift
//  AppLocalizer
//

import SwiftUI

/// One of What to make's three cards: a preview of the thing, its
/// checkbox and title, what it is, and, while it's on, its options.
/// Clicking the preview turns it on or off too.
struct GuidedMakeCard<Preview: View, Options: View>: View {
    let title: String
    let text: String
    @Binding var isOn: Bool
    let identifier: String
    @ViewBuilder let preview: () -> Preview
    @ViewBuilder let options: () -> Options

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Button {
                isOn.toggle()
            } label: {
                preview()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                    .opacity(isOn ? 1 : 0.55)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
            Toggle(title, isOn: $isOn)
                .toggleStyle(.checkbox)
                .font(.headline)
                .accessibilityIdentifier(identifier)
            Text(text)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            if isOn {
                options()
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(GuidedSelectableCard(isSelected: isOn))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(identifier).card")
    }
}
