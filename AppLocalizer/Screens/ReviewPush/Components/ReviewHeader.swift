//
//  ReviewHeader.swift
//  AppLocalizer
//

import SwiftUI

/// "Review changes", the count, the This app | All apps switch, the source
/// filter and "Reject All from Claude Code".
struct ReviewHeader: View {
    @Bindable var viewModel: ReviewPushViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Review changes")
                        .font(.title2.weight(.semibold))
                    Text(viewModel.subtitle)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                }
                Spacer()
                if let appName = viewModel.selectedAppName {
                    Picker("Scope", selection: $viewModel.scope) {
                        Text("\(appName) · \(viewModel.thisAppCount)").tag(ReviewScope.thisApp)
                        Text("All apps · \(viewModel.allAppsCount)").tag(ReviewScope.allApps)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    .accessibilityIdentifier("review.scope")
                }
            }
            HStack(spacing: Spacing.small) {
                Text("Source")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                Picker("Source", selection: $viewModel.sourceFilter) {
                    ForEach(viewModel.sourceOptions) { option in
                        Text("\(option.title) \(option.count)").tag(option.filter)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("review.sourceFilter")
                Spacer()
                ForEach(viewModel.assistantsInScope, id: \.self) { client in
                    Button("Reject All from \(client)", role: .destructive) {
                        viewModel.rejectAll(fromAssistant: client)
                    }
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .accessibilityIdentifier("review.rejectAll")
                }
            }
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.top, Spacing.xLarge)
        .padding(.bottom, Spacing.medium)
    }
}
