//
//  TemplateInspectorPicker.swift
//  AppLocalizer
//

import SwiftUI

/// A labelled segmented picker that never widens the inspector: beside
/// its label when it fits, under it when only that fits (iPhone, iPhone
/// Duo and iPad), and a pop-up menu beside the label when even that
/// doesn't (Standard, Hero, Two phones and Reviews; a longer language).
struct TemplateInspectorPicker<Value: Hashable, Options: View>: View {
    let label: String
    let selection: Binding<Value>
    let identifier: String?
    let options: () -> Options

    init(_ label: String, selection: Binding<Value>, identifier: String? = nil, @ViewBuilder options: @escaping () -> Options) {
        self.label = label
        self.selection = selection
        self.identifier = identifier
        self.options = options
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            TemplateInspectorRow(label: label) { segmented }
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(label)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                segmented
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            TemplateInspectorRow(label: label) {
                Picker(label, selection: selection, content: options)
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()
                    .accessibilityIdentifier(identifier ?? "")
            }
        }
    }

    private var segmented: some View {
        Picker(label, selection: selection, content: options)
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .accessibilityIdentifier(identifier ?? "")
    }
}
