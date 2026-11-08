//
//  RetentionSegmentedControl.swift
//  AppLocalizer
//

import SwiftUI

/// A compact segmented control drawn in SwiftUI, for the choices on the
/// Retention page that carry more than a title: a "New" tag, or a warning
/// dot on a language that runs over Apple's limits. Each segment is a
/// button marked selected for VoiceOver.
struct RetentionSegmentedControl<Value: Hashable>: View {
    let label: String
    let segments: [RetentionSegment<Value>]
    @Binding var selection: Value
    var identifier: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 2) {
            ForEach(segments) { segment in
                button(for: segment)
            }
        }
        .padding(2)
        .background(Palette.fill2, in: Capsule())
        .fixedSize()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier ?? "")
    }

    private func button(for segment: RetentionSegment<Value>) -> some View {
        let isSelected = segment.value == selection
        return Button {
            selection = segment.value
        } label: {
            HStack(spacing: Spacing.xxSmall) {
                Text(segment.title)
                    .lineLimit(1)
                if segment.hasWarning {
                    Circle()
                        .fill(Palette.warning)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                }
                if let badge = segment.badge {
                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.accentText)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Palette.accentTint, in: Capsule())
                }
            }
            .font(.callout)
            .foregroundStyle(isSelected ? Palette.label : Palette.label2)
            .padding(.horizontal, Spacing.small + 2)
            .padding(.vertical, 3)
            .background {
                if isSelected {
                    Capsule()
                        .fill(colorScheme == .dark ? Palette.fill3 : Color.white)
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.12), radius: 1, y: 0.5)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text([segment.title, segment.badge, segment.accessibilityNote].compactMap(\.self).joined(separator: ", ")))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(segment.identifier ?? "")
    }
}
