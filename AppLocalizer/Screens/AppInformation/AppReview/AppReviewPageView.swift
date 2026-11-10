//
//  AppReviewPageView.swift
//  AppLocalizer
//

import SwiftUI

/// App Review: who App Review contacts, the demo account when sign-in is
/// required, and notes for the reviewer, for the version in the menu.
struct AppReviewPageView: View {
    @Bindable var viewModel: AppInformationViewModel
    @FocusState private var focusedField: AppInformationSuggestionField?

    var body: some View {
        if let content = viewModel.content, let review = viewModel.review {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                AppInformationPageHeader(
                    title: AppInformationPage.appReview.title,
                    subtitle: AppInformationPage.appReview.summary(appName: viewModel.app.name, version: content.version?.versionString)
                ) {
                    Pill(
                        text: review.isComplete ? String(localized: "Complete") : String(localized: "Incomplete"),
                        style: review.isComplete ? .neutral : .warning
                    )
                    .accessibilityIdentifier("appInformation.review.status")
                    if let version = content.version {
                        AppInformationVersionMenu(versions: content.versions, selected: version) { id in
                            Task { await viewModel.selectVersion(id) }
                        }
                    }
                }
                if let version = content.version, !content.isVersionEditable {
                    ReadOnlyVersionNote(version: version, editable: content.editableVersion)
                }
                AppInformationPageBar(viewModel: viewModel, page: .appReview)
                AppInformationSuggestionsPanel(viewModel: viewModel, page: .appReview)
                Group {
                    if !contactFields.isEmpty {
                        contactSection(review)
                    }
                    if !viewModel.showsOnlySuggestedFields {
                        signInSection(review)
                    }
                    if viewModel.showsField(.notes) {
                        notesSection(review)
                    }
                }
                .disabled(!viewModel.isReviewEditable)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("appInformation.appReview")
            .onChange(of: viewModel.focusRequest, initial: true) {
                guard let field = viewModel.focusRequest, field.page == .appReview else { return }
                focusedField = field
                viewModel.focusRequest = nil
            }
        }
    }

    /// The contact rows "Only fields with suggestions or changes" leaves.
    private var contactFields: [AppReviewField] {
        [AppReviewField.firstName, .lastName, .phone, .email].filter { field in
            AppInformationSuggestionField(reviewField: field).map(viewModel.showsField) ?? true
        }
    }

    private func contactSection(_ review: AppReviewValues) -> some View {
        AppInformationFormSection(title: String(localized: "Contact")) {
            ForEach(Array(contactFields.enumerated()), id: \.element) { index, field in
                if index > 0 { Divider() }
                textRow(field, review)
                if let suggestionField = AppInformationSuggestionField(reviewField: field) {
                    AppInformationFieldSuggestions(viewModel: viewModel, field: suggestionField)
                }
            }
        }
    }

    private func signInSection(_ review: AppReviewValues) -> some View {
        AppInformationFormSection(title: String(localized: "Sign-in")) {
            AppInformationFormRow(label: AppReviewField.signInRequired.title, detail: String(localized: "App Review needs a demo account to get past it")) {
                Toggle(AppReviewField.signInRequired.title, isOn: Binding(get: { review.signInRequired }, set: { viewModel.setSignInRequired($0) }))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .accessibilityIdentifier("appInformation.review.signInRequired")
            }
            if review.signInRequired {
                Divider()
                textRow(.userName, review)
                Divider()
                AppInformationFormRow(label: AppReviewField.password.title) {
                    PasswordField(title: AppReviewField.password.title, text: review.password, isVisible: $viewModel.isPasswordVisible) {
                        viewModel.setReviewText($0, for: .password)
                    }
                }
            }
        }
    }

    private func notesSection(_ review: AppReviewValues) -> some View {
        let count = review.notes.count
        let isOver = count > AppReviewField.notesLimit
        return VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack {
                Text(AppReviewField.notes.title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(count.formatted()) / \(AppReviewField.notesLimit.formatted())")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(isOver ? Palette.danger : Palette.label2)
                    .accessibilityLabel(Text("\(count) of \(AppReviewField.notesLimit) characters"))
                    .accessibilityIdentifier("appInformation.review.notesCount")
            }
            TextEditor(text: Binding(get: { review.notes }, set: { viewModel.setReviewText($0, for: .notes) }))
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(Spacing.xSmall)
                .frame(minHeight: 96)
                .background(Palette.content, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                        .strokeBorder(isOver ? Palette.dangerMark : Palette.separator2, lineWidth: isOver ? 1.5 : 0.5)
                }
                .focused($focusedField, equals: .notes)
                .accessibilityLabel(Text(AppReviewField.notes.title))
                .accessibilityIdentifier("appInformation.review.notes")
            if isOver {
                Text("App Store Connect takes up to \(AppReviewField.notesLimit.formatted()) characters. Shorten the notes to push them.")
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
            }
            AppInformationFieldSuggestions(viewModel: viewModel, field: .notes)
                .padding(.horizontal, -(Spacing.medium + 2))
        }
    }

    private func textRow(_ field: AppReviewField, _ review: AppReviewValues) -> some View {
        AppInformationFormRow(label: field.title) {
            TextField(field.title, text: Binding(get: { review.text(field) }, set: { viewModel.setReviewText($0, for: field) }))
                .labelsHidden()
                .textContentType(field == .userName ? .username : nil)
                .frame(width: 260)
                .focused($focusedField, equals: AppInformationSuggestionField(reviewField: field))
                .accessibilityIdentifier("appInformation.review.\(field.rawValue)")
        }
    }
}
