//
//  BadgedSegments.swift
//  AppLocalizer
//

import SwiftUI

/// A small segmented control whose segments carry a suggestion count, which
/// a system picker can't draw: Prices | Retention, iPhone | Apple Watch.
struct BadgedSegments<Value: Hashable>: View {
    let label: String
    let options: [(value: Value, title: String, count: Int)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.value) { option in
                Button {
                    selection = option.value
                } label: {
                    HStack(spacing: Spacing.xSmall) {
                        Text(option.title)
                        SuggestionBadge(count: option.count, isSmall: true)
                    }
                    .font(.subheadline.weight(selection == option.value ? .medium : .regular))
                    .padding(.horizontal, 10)
                    .frame(minHeight: 22)
                    .background {
                        if selection == option.value {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Palette.raised)
                                .shadow(color: .black.opacity(0.12), radius: 1, y: 0.5)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(accessibilityText(option.title, count: option.count)))
                .accessibilityAddTraits(selection == option.value ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(2)
        .background(Palette.fill2, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .fixedSize()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(label))
    }

    private func accessibilityText(_ title: String, count: Int) -> String {
        switch count {
        case 0: title
        case 1: String(localized: "\(title), 1 suggestion to review")
        default: String(localized: "\(title), \(count) suggestions to review")
        }
    }
}

#Preview {
    @Previewable @State var selection = "a"
    BadgedSegments(label: "View", options: [("a", "Prices", 3), ("b", "Retention", 0)], selection: $selection)
        .padding()
}
