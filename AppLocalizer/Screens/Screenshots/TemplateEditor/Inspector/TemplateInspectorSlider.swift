//
//  TemplateInspectorSlider.swift
//  AppLocalizer
//

import SwiftUI

/// A labelled slider with its value beside it, e.g. Size · 112 u.
struct TemplateInspectorSlider: View {
    let label: String
    let value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    /// After the whole number: " u" makes "112 u", "%" makes "80%".
    let unit: String
    /// Up to this many decimals: 1 makes "6.5%".
    var fractionDigits = 0
    let onChange: (Double) -> Void

    var body: some View {
        TemplateInspectorRow(label: label) {
            HStack(spacing: Spacing.small) {
                Slider(value: Binding { value } set: { onChange(($0 / step).rounded() * step) }, in: range)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel(Text(label))
                    .accessibilityValue(Text(formatted))
                Text(formatted)
                    .font(.callout)
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    private var formatted: String {
        "\(value.formatted(.number.precision(.fractionLength(0...fractionDigits))))\(unit)"
    }
}
