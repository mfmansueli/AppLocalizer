//
//  CaptionsToolbar.swift
//  AppLocalizer
//

import SwiftUI

/// Translate Missing…, the filter and the counts.
struct CaptionsToolbar: View {
    @Bindable var model: CaptionsViewModel
    let onTranslate: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.small) {
                controls
                Spacer(minLength: Spacing.small)
                stats
            }
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack(spacing: Spacing.small) { controls }
                stats
            }
        }
        .controlSize(.small)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }

    @ViewBuilder
    private var controls: some View {
        Button("Translate Missing…", systemImage: "globe", action: onTranslate)
            .buttonStyle(.borderedProminent)
            .disabled(model.translation.isRunning)
            .accessibilityIdentifier("screenshots.captions.translate")
        Picker("Filter", selection: $model.filter) {
            ForEach(CaptionsFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .accessibilityIdentifier("screenshots.captions.filter")
    }

    private var stats: some View {
        Text(model.stats)
            .font(.callout)
            .monospacedDigit()
            .foregroundStyle(Palette.label2)
            .lineLimit(1)
            .accessibilityIdentifier("screenshots.captions.stats")
    }
}
