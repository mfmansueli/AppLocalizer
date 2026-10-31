//
//  StorePageContextBar.swift
//  AppLocalizer
//

import SwiftUI

/// The Store Page's section bar: the version picker (with which fields are
/// app-level), "Live · read-only" for a version that can't change, and the
/// views: Coverage | Editor | In-App Texts | Screenshots.
struct StorePageContextBar: View {
    @Bindable var viewModel: StorePageViewModel

    var body: some View {
        SectionBar {
            versionMenu
            if let version = viewModel.content?.version, !version.isEditable {
                Pill(text: String(localized: "Live · read-only"), systemImage: "lock", style: .outline)
                    .fixedSize()
                    .accessibilityIdentifier("storePage.readOnly")
            }
        } trailing: {
            FittingSegmentedPicker(
                label: String(localized: "Store Page views"),
                options: StorePageMode.allCases.map { ($0, $0.title) },
                selection: $viewModel.mode
            )
            .fixedSize()
            .accessibilityIdentifier("storePage.modePicker")
        }
    }

    @ViewBuilder
    private var versionMenu: some View {
        if let content = viewModel.content {
            Menu {
                Section("Versions") {
                    ForEach(content.versions) { version in
                        Button {
                            Task { await viewModel.selectVersion(version.id) }
                        } label: {
                            if version.id == content.version.id {
                                Image(systemName: "checkmark")
                            }
                            Text(version.listingVersion.pickerTitle)
                            Text(version.listingVersion.pickerSubtitle)
                        }
                        .accessibilityIdentifier("storePage.version.\(version.versionString)")
                    }
                }
            } label: {
                title(content.version.listingVersion.title)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel(Text("Version, \(content.version.listingVersion.title)"))
            .accessibilityIdentifier("storePage.versionPicker")
        } else {
            title(String(localized: "Store Page"))
        }
    }

    private func title(_ text: String) -> some View {
        SectionBarTitle(
            systemImage: "doc",
            title: text,
            subtitle: subtitle,
            showsChevron: viewModel.content != nil
        )
    }

    private var subtitle: String {
        String(localized: "Name, Subtitle and Privacy URL are app-level; everything else is per version")
    }
}
