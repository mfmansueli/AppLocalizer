//
//  AssistantSetupOptionRow.swift
//  AppLocalizer
//

import SwiftUI

/// One choice in the setup sheet's lists (the method, the assistant, the
/// permission): a radio mark, the name with an optional pill, a line saying
/// what it means, and for a method its pluses and minus. The chosen one is
/// tinted and outlined in the accent color.
struct AssistantSetupOptionRow: View {
    let title: String
    let detail: String
    var badge: String?
    var points: [(isPlus: Bool, text: String)] = []
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Palette.accent : Palette.label3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xSmall) {
                        Text(title)
                            .font(.callout.weight(.semibold))
                        if let badge {
                            Pill(text: badge, style: .accent)
                        }
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                    if !points.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                                HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                                    Text(point.isPlus ? "+" : "−")
                                        .font(.caption.weight(.semibold).monospaced())
                                        .foregroundStyle(point.isPlus ? Palette.positive : Palette.label2)
                                    Text(point.text)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.top, Spacing.xxSmall)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, 10)
            .background(isSelected ? Palette.accentTint : Palette.fill1, in: shape)
            .overlay(shape.strokeBorder(isSelected ? Palette.accent : Palette.separator2, lineWidth: isSelected ? 1.5 : 0.5))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(badge.map { "\(title), \($0)" } ?? title))
        .accessibilityHint(Text(([detail] + points.map { ($0.isPlus ? "+ " : "− ") + $0.text }).joined(separator: ". ")))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
    }
}

#Preview {
    VStack {
        AssistantSetupOptionRow(title: "Claude Code", detail: "Works in your project folder.", badge: "Recommended", isSelected: true) {}
        AssistantSetupOptionRow(title: "Cursor", detail: "Works with the project you have open in Cursor.", isSelected: false) {}
    }
    .padding()
    .frame(width: 600)
}
