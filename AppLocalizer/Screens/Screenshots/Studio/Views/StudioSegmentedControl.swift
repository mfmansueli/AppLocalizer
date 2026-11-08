//
//  StudioSegmentedControl.swift
//  AppLocalizer
//

import SwiftUI

/// The Studio's small capsule segmented controls (device, language,
/// Live · New, Light · Dark), where one segment can be disabled, or dimmed
/// (a device the run doesn't make yet) and still picked.
struct StudioSegmentedControl<Value: Hashable>: View {
    struct Option {
        var value: Value
        var title: String
        var isEnabled = true
        /// The segment's identifier suffix.
        var key: String
        /// The segment's tooltip ("iPhone 6.9″ · 1320 × 2868").
        var help: String?
        /// Shown fainter unless it's picked.
        var isDimmed = false
    }

    let label: String
    let options: [Option]
    @Binding var selection: Value
    let identifier: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.key) { option in
                let isSelected = selection == option.value
                Button {
                    selection = option.value
                } label: {
                    Text(option.title)
                        .font(.callout)
                        .lineLimit(1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background {
                            if isSelected {
                                Capsule().fill(Palette.raised).shadow(color: .black.opacity(0.12), radius: 1, y: 0.5)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(option.isEnabled ? Palette.label : Palette.label3)
                .opacity(option.isDimmed && !isSelected ? 0.62 : 1)
                .disabled(!option.isEnabled)
                .help(option.help.map { Text($0) } ?? Text(""))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("\(identifier).\(option.key)")
            }
        }
        .padding(2)
        .background(Palette.fill2, in: Capsule())
        .fixedSize()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(label))
        .accessibilityIdentifier(identifier)
    }
}
