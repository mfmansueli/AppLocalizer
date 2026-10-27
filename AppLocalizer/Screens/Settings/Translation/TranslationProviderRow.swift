//
//  TranslationProviderRow.swift
//  AppLocalizer
//

import SwiftUI

/// One choice of Settings → Translation → Provider: a radio button with the
/// provider's name and what it's good at, and room on the right for its own
/// controls (the AI provider's vendor and API key).
struct TranslationProviderRow<Accessory: View>: View {
    let provider: TranslationProvider
    @Binding var selection: TranslationProvider
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.medium) {
            Button {
                selection = provider
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(isSelected ? Palette.accent : Palette.label3)
                        .imageScale(.large)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(provider.title)
                            .font(.body.weight(.medium))
                        Text(provider.summary)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(provider.title))
            .accessibilityHint(Text(provider.summary))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("settings.provider.\(provider.rawValue)")
            accessory()
        }
    }

    private var isSelected: Bool { selection == provider }
}

extension TranslationProviderRow where Accessory == EmptyView {
    init(provider: TranslationProvider, selection: Binding<TranslationProvider>) {
        self.init(provider: provider, selection: selection) { EmptyView() }
    }
}
