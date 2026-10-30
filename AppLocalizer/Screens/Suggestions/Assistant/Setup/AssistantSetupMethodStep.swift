//
//  AssistantSetupMethodStep.swift
//  AppLocalizer
//

import SwiftUI

/// Step 1: an assistant over MCP or an API key, each with what it gives
/// up, then which assistant, or what a key can't do.
struct AssistantSetupMethodStep: View {
    let viewModel: AssistantSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How should AppLocalizer get AI suggestions?")
                .font(.callout)
                .foregroundStyle(Palette.label2)
            HStack(alignment: .top, spacing: Spacing.small) {
                ForEach(AssistantSetupMethod.allCases) { method in
                    AssistantSetupOptionRow(
                        title: method.title,
                        detail: method.detail,
                        points: method.points,
                        isSelected: viewModel.method == method
                    ) {
                        viewModel.choose(method)
                    }
                    .accessibilityIdentifier("assistantSetup.method.\(method.rawValue)")
                }
            }
            if viewModel.usesKey {
                InlineMessage(
                    text: String(localized: """
                    An API key works without any other app. It doesn’t read your code, so App Review notes and category \
                    checks still need an assistant like Claude Code.
                    """),
                    systemImage: "info.circle",
                    tint: Palette.label2
                )
                .font(.caption)
            } else {
                Text("Which assistant?")
                    .font(.headline)
                    .padding(.top, Spacing.xxSmall)
                VStack(spacing: Spacing.xSmall) {
                    ForEach(MCPClientKind.allCases) { kind in
                        AssistantSetupOptionRow(
                            title: kind.setupName,
                            detail: kind.setupDescription,
                            badge: kind == .claudeCode ? String(localized: "Recommended") : nil,
                            isSelected: viewModel.kind == kind
                        ) {
                            viewModel.choose(kind)
                        }
                        .accessibilityIdentifier("assistantSetup.client.\(kind.rawValue)")
                    }
                }
            }
        }
    }
}
