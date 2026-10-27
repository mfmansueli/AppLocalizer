//
//  FindReplaceSheet.swift
//  AppLocalizer
//

import SwiftUI

/// "Find and replace across locales" (⌥⌘F): what to find and what to put
/// instead, every match in context, and Replace All, which turns each
/// changed field into your edit.
struct FindReplaceSheet: View {
    @Bindable var viewModel: StorePageViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFindFocused: Bool

    var body: some View {
        let matches = viewModel.findMatches
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Find and replace across locales")
                    .font(.title2.weight(.semibold))
                Text(scopeDescription)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .padding([.horizontal, .top], Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(spacing: Spacing.small) {
                    labeledField("Find", text: $viewModel.findQuery.find, identifier: "storePage.find.query")
                        .focused($isFindFocused)
                    labeledField("Replace with", text: $viewModel.findQuery.replacement, identifier: "storePage.find.replacement")
                }
                Toggle("Match case", isOn: $viewModel.findQuery.isCaseSensitive)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                results(matches)
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            Divider()
            HStack(spacing: Spacing.small) {
                Text(matches.count == 1 ? "1 match" : "\(matches.count) matches")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("storePage.find.count")
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Replace All") {
                    viewModel.replaceAll()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(matches.isEmpty)
                .accessibilityIdentifier("storePage.find.replaceAll")
            }
            .padding(Spacing.large)
        }
        .frame(width: 640)
        .onAppear { isFindFocused = true }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.findSheet")
    }

    /// "Promotional Text, Description and What's New · case-sensitive".
    private var scopeDescription: String {
        let fields = ListingField.allCases.filter(viewModel.findQuery.fields.contains).map(\.title)
        let names = ListFormatter.localizedString(byJoining: fields)
        let sensitivity = viewModel.findQuery.isCaseSensitive ? String(localized: "case-sensitive") : String(localized: "ignoring case")
        return "\(names) · \(sensitivity)"
    }

    private func labeledField(_ title: LocalizedStringKey, text: Binding<String>, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .accessibilityIdentifier(identifier)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func results(_ matches: [FindReplaceMatch]) -> some View {
        if !viewModel.findQuery.isEmpty {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(matches) { match in
                        FindReplaceMatchRow(match: match)
                        Divider()
                    }
                    if matches.isEmpty {
                        Text("No matches.")
                            .font(.callout)
                            .foregroundStyle(Palette.label2)
                            .padding(Spacing.medium)
                    }
                }
            }
            .frame(height: 280)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
            .accessibilityIdentifier("storePage.find.results")
        }
    }
}
