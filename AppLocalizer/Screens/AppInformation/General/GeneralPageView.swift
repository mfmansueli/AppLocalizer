//
//  GeneralPageView.swift
//  AppLocalizer
//

import SwiftUI

/// General: category and content rights for the whole app; copyright and
/// release for the version picked in the version menu.
struct GeneralPageView: View {
    @Bindable var viewModel: AppInformationViewModel
    @FocusState private var isCopyrightFocused: Bool

    var body: some View {
        if let content = viewModel.content, let general = viewModel.general {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                AppInformationPageHeader(
                    title: AppInformationPage.general.title,
                    subtitle: AppInformationPage.general.summary(appName: viewModel.app.name, version: content.version?.versionString)
                )
                AppInformationPageBar(viewModel: viewModel, page: .general)
                AppInformationSuggestionsPanel(viewModel: viewModel, page: .general)
                if showsCategories {
                    categorySection(general)
                }
                if !viewModel.showsOnlySuggestedFields {
                    contentRightsSection(general)
                }
                if let version = content.version, showsVersion {
                    versionSection(general, content: content, version: version)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("appInformation.general")
            .onChange(of: viewModel.focusRequest, initial: true) {
                guard viewModel.focusRequest == .copyright else { return }
                isCopyrightFocused = true
                viewModel.focusRequest = nil
            }
        }
    }

    /// With "Only fields with suggestions or changes" on, a section shows
    /// while one of its suggestion fields does.
    private var showsCategories: Bool {
        viewModel.showsField(.primaryCategory) || viewModel.showsField(.secondaryCategory)
    }

    private var showsVersion: Bool {
        viewModel.showsField(.copyright) || viewModel.showsField(.release)
    }

    private func categorySection(_ general: GeneralValues) -> some View {
        AppInformationFormSection(title: String(localized: "Category")) {
            if viewModel.showsField(.primaryCategory) {
                AppInformationFormRow(label: String(localized: "Primary")) {
                    CategoryPicker(title: String(localized: "Primary category"), selection: general.primaryCategory, categories: AppCategory.all) {
                        viewModel.setPrimaryCategory($0)
                    }
                    .accessibilityIdentifier("appInformation.general.primaryCategory")
                }
                AppInformationFieldSuggestions(viewModel: viewModel, field: .primaryCategory)
            }
            if viewModel.showsField(.secondaryCategory) {
                if viewModel.showsField(.primaryCategory) { Divider() }
                AppInformationFormRow(label: String(localized: "Secondary"), detail: String(localized: "· optional")) {
                    CategoryPicker(
                        title: String(localized: "Secondary category"),
                        selection: general.secondaryCategory,
                        categories: AppCategory.all.filter { $0.id != general.primaryCategory },
                        allowsNone: true
                    ) { viewModel.setSecondaryCategory($0) }
                        .accessibilityIdentifier("appInformation.general.secondaryCategory")
                }
                AppInformationFieldSuggestions(viewModel: viewModel, field: .secondaryCategory)
            }
            if general.isGame, !viewModel.showsOnlySuggestedFields {
                Divider()
                AppInformationFormRow(label: String(localized: "Games subcategories"), detail: String(localized: "· up to two")) {
                    HStack(spacing: Spacing.small) {
                        ForEach(0..<2, id: \.self) { index in
                            CategoryPicker(
                                title: String(localized: "Games subcategory \(index + 1)"),
                                selection: general.gamesSubcategories.indices.contains(index) ? general.gamesSubcategories[index] : nil,
                                categories: AppCategory.gamesSubcategories,
                                allowsNone: true
                            ) { viewModel.setGamesSubcategory($0, at: index) }
                                .disabled(index > general.gamesSubcategories.count)
                        }
                    }
                }
            }
        }
    }

    private func contentRightsSection(_ general: GeneralValues) -> some View {
        AppInformationFormSection(title: String(localized: "Content rights")) {
            AppInformationFormRow(label: String(localized: "Does the app contain, show or access third-party content?")) {
                YesNoPicker(title: String(localized: "Third-party content"), value: general.contentRights.map { $0 == .usesThirdPartyContent }) {
                    viewModel.setContentRights($0 ? .usesThirdPartyContent : .doesNotUseThirdPartyContent)
                }
                .accessibilityIdentifier("appInformation.general.thirdPartyContent")
            }
            if general.contentRights == .usesThirdPartyContent {
                Divider()
                AppInformationFormRow(label: String(localized: "I have the rights to use it, or it’s otherwise permitted")) {
                    Toggle(
                        String(localized: "Rights confirmed"),
                        isOn: Binding(get: { general.rightsConfirmed }, set: { viewModel.setRightsConfirmed($0) })
                    )
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .accessibilityIdentifier("appInformation.general.rightsConfirmed")
                }
            }
        }
    }

    private func versionSection(_ general: GeneralValues, content: AppInformationContent, version: StorePageVersion) -> some View {
        AppInformationFormSection(title: String(localized: "Version \(version.versionString)")) {
            if viewModel.showsField(.copyright) {
                AppInformationFormRow(label: String(localized: "Copyright")) {
                    TextField(
                        String(localized: "Copyright"),
                        text: Binding(get: { general.copyright }, set: { viewModel.setCopyright($0) }),
                        prompt: Text("© 2026 Your Company")
                    )
                    .labelsHidden()
                    .frame(width: 260)
                    .focused($isCopyrightFocused)
                    .disabled(!content.isVersionEditable)
                    .accessibilityIdentifier("appInformation.general.copyright")
                }
                AppInformationFieldSuggestions(viewModel: viewModel, field: .copyright)
            }
            if viewModel.showsField(.release) {
                if viewModel.showsField(.copyright) { Divider() }
                releaseRows(general, content: content)
            }
            if !content.isVersionEditable {
                Divider()
                ReadOnlyVersionNote(version: version, editable: content.editableVersion)
            }
        } trailing: {
            AppInformationVersionMenu(versions: content.versions, selected: version) { id in
                Task { await viewModel.selectVersion(id) }
            }
        }
    }

    @ViewBuilder
    private func releaseRows(_ general: GeneralValues, content: AppInformationContent) -> some View {
        AppInformationFormRow(label: String(localized: "Release")) {
            Picker(String(localized: "Release"), selection: Binding(get: { general.release }, set: { $0.map(viewModel.setRelease) })) {
                ForEach(ReleaseOption.allCases) { option in
                    Text(option.title).tag(ReleaseOption?.some(option))
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .disabled(!content.isVersionEditable)
            .accessibilityIdentifier("appInformation.general.release")
        }
        AppInformationFieldSuggestions(viewModel: viewModel, field: .release)
        if general.release == .scheduled {
            Divider()
            AppInformationFormRow(label: String(localized: "Release date"), detail: String(localized: "· earliest, after approval")) {
                DatePicker(
                    String(localized: "Release date"),
                    selection: Binding(get: { general.earliestReleaseDate ?? .now }, set: { viewModel.setReleaseDate($0) }),
                    in: Date.now...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .disabled(!content.isVersionEditable)
                .accessibilityIdentifier("appInformation.general.releaseDate")
            }
        }
    }
}
