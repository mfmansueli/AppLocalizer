//
//  KeyAssistantSetupKeyStep.swift
//  AppLocalizer
//

import SwiftUI

/// Step 2 with a key: the provider, the key with Check Key, what the check
/// found (or "Get a key from Anthropic ↗"), the model, whether
/// translations use the key too, and where the key goes.
struct KeyAssistantSetupKeyStep: View {
    @Bindable var viewModel: KeyAssistantSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: Spacing.medium, verticalSpacing: 10) {
                GridRow {
                    Text("Provider")
                        .gridColumnAlignment(.trailing)
                    Picker("Provider", selection: $viewModel.vendor) {
                        ForEach(AIProviderVendor.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    .accessibilityIdentifier("keySetup.provider")
                }
                GridRow {
                    Text("API key")
                    HStack(spacing: Spacing.small) {
                        SecureField("API key", text: $viewModel.key, prompt: Text(viewModel.keyPlaceholder))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .font(.callout.monospaced())
                            .onSubmit { Task { await viewModel.checkKey() } }
                            .accessibilityIdentifier("keySetup.key")
                        Button("Check Key") { Task { await viewModel.checkKey() } }
                            .disabled(viewModel.keyState == .checking)
                            .accessibilityIdentifier("keySetup.check")
                    }
                }
                GridRow {
                    Color.clear.frame(width: 1, height: 1)
                    status
                }
                GridRow {
                    Text("Model")
                    Picker("Model", selection: $viewModel.modelID) {
                        if viewModel.models.isEmpty {
                            Text("Check the key to load models").tag(KeyAssistantModel.ID?.none)
                        }
                        ForEach(viewModel.models) { Text($0.pickerTitle).tag(KeyAssistantModel.ID?.some($0.id)) }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .disabled(viewModel.models.isEmpty)
                    .accessibilityIdentifier("keySetup.model")
                }
                GridRow {
                    Color.clear.frame(width: 1, height: 1)
                    Toggle("Also use this key for translations (Settings → Translation)", isOn: $viewModel.usesKeyForTranslations)
                        .toggleStyle(.checkbox)
                        .accessibilityIdentifier("keySetup.translations")
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                ForEach(viewModel.keyFacts, id: \.text) { fact in
                    Label {
                        Text(fact.text)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: fact.systemImage)
                            .foregroundStyle(Palette.label2)
                    }
                }
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5))
        }
    }

    private var status: some View {
        Group {
            switch viewModel.keyState {
            case .idle:
                Link("Get a key from \(viewModel.vendor.title) ↗", destination: viewModel.vendor.keyPageURL)
            case .checking:
                HStack(spacing: Spacing.xSmall) {
                    ProgressView().controlSize(.small)
                    Text("Checking with \(viewModel.vendor.title)…")
                }
            case let .works(text):
                Label(text, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Palette.positive)
            case let .rejected(text):
                Label(text, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Palette.danger)
            }
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("keySetup.status")
    }
}
