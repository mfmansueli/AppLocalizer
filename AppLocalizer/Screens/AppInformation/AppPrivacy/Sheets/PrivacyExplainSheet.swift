//
//  PrivacyExplainSheet.swift
//  AppLocalizer
//

import SwiftUI

/// "Not Collected, Explain…": why a type an SDK's manifest declares isn't
/// collected after all. The reason stays with the worksheet and the
/// cross-check stops flagging it.
struct PrivacyExplainSheet: View {
    let viewModel: AppPrivacyViewModel
    let type: PrivacyDataType
    @State private var reason = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Why isn’t \(type.name) collected?")
                    .font(.title3.weight(.semibold))
                Text(declaredBy)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            TextField(
                String(localized: "Reason"),
                text: $reason,
                prompt: Text("e.g. Diagnostics are turned off with sendDefaultPii = false"),
                axis: .vertical
            )
            .lineLimit(3...6)
            .textFieldStyle(.roundedBorder)
            .accessibilityIdentifier("appInformation.appPrivacy.explain.reason")
            HStack {
                Spacer()
                Button(String(localized: "Cancel"), role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(String(localized: "Keep Not Collected")) {
                    viewModel.explainNotCollected(type, because: reason)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("appInformation.appPrivacy.explain.save")
            }
        }
        .padding(Spacing.xLarge)
        .frame(width: 460)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.explainSheet")
    }

    private var declaredBy: String {
        let sdks = viewModel.worksheet.manifestDeclarations[type] ?? []
        guard !sdks.isEmpty else {
            return String(localized: "The reason is kept with the worksheet, and the cross-check stops flagging it.")
        }
        let names = sdks.formatted(.list(type: .and))
        return String(localized: "\(names) declares it in a privacy manifest. The reason is kept with the worksheet.")
    }
}
