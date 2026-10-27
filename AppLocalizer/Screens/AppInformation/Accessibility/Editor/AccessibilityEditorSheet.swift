//
//  AccessibilityEditorSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Declaring or editing one family: Yes/No first, then the bar and the
/// features the platform has, each with its criteria. Save queues the
/// answer; publishing is chosen in Review & Push.
struct AccessibilityEditorSheet: View {
    @Bindable var viewModel: AppInformationViewModel
    let draft: AccessibilityEditorDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                header
                question
                if draft.supportsAny == true {
                    AccessibilityEditorBar(appName: viewModel.app.name, tasks: viewModel.notes.commonTasks)
                    checklist
                    ForEach(draft.family.unavailableFeatures) { feature in
                        Text(feature.unavailableReason(on: draft.family))
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .accessibilityIdentifier("appInformation.accessibility.editor.hidden")
                    }
                } else if draft.supportsAny == false {
                    Label(
                        String(localized: """
                        The product page will say \(viewModel.app.name) doesn’t indicate support for any accessibility features on \
                        \(draft.family.name).
                        """),
                        systemImage: "info.circle"
                    )
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                }
                if let message = viewModel.editorMessage {
                    Label(message, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("appInformation.accessibility.editor.message")
                }
            }
            .padding(.horizontal, Spacing.xxLarge - 2)
            .padding(.top, Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            Divider()
            footer
        }
        .frame(width: 640)
        .frame(minHeight: 420, idealHeight: 700, maxHeight: 760)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.accessibility.editor")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Accessibility · \(draft.family.name)")
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(draft.published == nil
                ? String(localized: "Not on the product page yet. Answer for \(draft.family.name) as people use it there.")
                : String(localized: "On the product page now. Answer for \(draft.family.name) as people use it there."))
                .font(.callout)
                .foregroundStyle(Palette.label2)
        }
    }

    private var question: some View {
        HStack {
            Text("Does your app support any of these features on \(draft.family.name)?")
                .fontWeight(.medium)
            Spacer(minLength: Spacing.medium)
            YesNoPicker(title: String(localized: "Supports accessibility features"), value: draft.supportsAny) {
                viewModel.editor?.supportsAny = $0
            }
            .accessibilityIdentifier("appInformation.accessibility.editor.supportsAny")
        }
        .padding(.horizontal, Spacing.medium + 2)
        .padding(.vertical, Spacing.small + 2)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
    }

    private var checklist: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(draft.availableFeatures.enumerated()), id: \.element) { index, feature in
                    if index > 0 { Divider() }
                    AccessibilityFeatureRow(
                        feature: feature,
                        isChecked: draft.isChecked(feature),
                        status: draft.status(of: feature),
                        suggestion: draft.suggestion(for: feature)
                    ) { viewModel.editor?.toggle(feature) }
                }
            }
        }
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.accessibility.editor.features")
    }

    private var footer: some View {
        HStack(spacing: Spacing.medium) {
            if viewModel.canCopyFromIPhone(to: draft.family) {
                Button(String(localized: "Copy from iPhone")) { viewModel.copyIntoEditor() }
                    .accessibilityIdentifier("appInformation.accessibility.editor.copy")
            }
            Text("Saved here as a pending change. Publishing happens from Review & Push.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.medium)
            Button(String(localized: "Cancel"), role: .cancel) { viewModel.cancelEditor() }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("appInformation.accessibility.editor.cancel")
            Button(String(localized: "Save")) { viewModel.saveEditor() }
                .keyboardShortcut(.defaultAction)
                .disabled(draft.answer == nil)
                .help(draft.saveBlocker ?? "")
                .accessibilityIdentifier("appInformation.accessibility.editor.save")
        }
        .controlSize(.large)
        .padding(.horizontal, Spacing.large + 2)
        .padding(.vertical, Spacing.medium + 2)
    }
}
