//
//  AssetLibrarySheet.swift
//  AppLocalizer
//

import SwiftUI

/// The app's App Asset Library on App Store Connect: every image and video
/// uploaded for it (by Autopilot's pushes or anyone else), which are on a
/// page, and deleting several at once after a confirmation. Leftovers, such
/// as files a later push replaced, are on no page.
struct AssetLibrarySheet: View {
    @Bindable var model: AssetLibraryModel

    @Environment(\.dismiss) private var dismiss
    @State private var confirmsDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text("App Asset Library").font(.title3.weight(.semibold))
                Text("\(model.appName) · files uploaded to App Store Connect").font(.callout).foregroundStyle(Palette.label2)
            }
            Text("A file a page still shows can’t be deleted; take it off the page first. Files a later push replaced are on no page.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            controls
            content
            status
            footer
        }
        .padding(Spacing.large)
        .frame(width: 760, height: 620)
        .task { await model.load() }
        .confirmationDialog(model.confirmationTitle, isPresented: $confirmsDelete) {
            Button(model.deleteTitle.replacingOccurrences(of: "…", with: ""), role: .destructive) {
                Task { await model.deleteSelected() }
            }
            .accessibilityIdentifier("assetLibrary.confirmDelete")
        } message: {
            Text("They’re removed from App Store Connect for good. Files on a page aren’t touched.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assetLibrary.sheet")
    }

    private var controls: some View {
        HStack(spacing: Spacing.small) {
            Picker("Kind", selection: $model.kind) {
                ForEach(AssetLibraryKindFilter.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .accessibilityIdentifier("assetLibrary.kind")
            Toggle("Only on no page", isOn: $model.onlyUnused)
                .toggleStyle(.checkbox)
                .accessibilityIdentifier("assetLibrary.onlyUnused")
            TextField("Search names", text: $model.search)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 220)
                .accessibilityIdentifier("assetLibrary.search")
            Spacer(minLength: 0)
            Button("Select Unused") { model.selectUnused() }
                .disabled(model.isDeleting || model.phase != .loaded)
                .accessibilityIdentifier("assetLibrary.selectUnused")
            Button("Select None") { model.selectNone() }
                .disabled(model.selection.isEmpty || model.isDeleting)
                .accessibilityIdentifier("assetLibrary.selectNone")
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView("Reading the library…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("assetLibrary.loading")
        case let .failed(reason):
            VStack(spacing: Spacing.small) {
                Text("Couldn’t read the library").font(.headline)
                Text(reason).font(.callout).foregroundStyle(Palette.label2).multilineTextAlignment(.center).textSelection(.enabled)
                Button("Try Again") { Task { await model.load() } }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("assetLibrary.failed")
        case .loaded:
            let files = model.visibleFiles
            if files.isEmpty {
                ContentUnavailableView(
                    model.files.isEmpty ? String(localized: "The library is empty") : String(localized: "Nothing matches"),
                    systemImage: "photo.on.rectangle.angled"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("assetLibrary.empty")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(files) { file in
                            AssetLibraryFileRow(file: file, model: model)
                            Divider()
                        }
                    }
                }
                .background(Palette.raised, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5)
                }
                .accessibilityIdentifier("assetLibrary.list")
            }
        }
    }

    private var status: some View {
        HStack(spacing: Spacing.small) {
            if let deleting = model.deletingTitle {
                ProgressView().controlSize(.small)
                Text(deleting)
            } else if let notice = model.notice {
                Text(notice).foregroundStyle(model.deleteErrors.isEmpty ? Palette.label : Palette.danger)
            } else if model.phase == .loaded {
                Text(model.summaryTitle).foregroundStyle(Palette.label2)
            }
        }
        .font(.caption)
        .monospacedDigit()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("assetLibrary.status")
    }

    private var footer: some View {
        HStack(spacing: Spacing.small) {
            if let selected = model.selectionTitle {
                Text(selected).font(.callout).foregroundStyle(Palette.label2).accessibilityIdentifier("assetLibrary.selected")
            }
            Spacer()
            Button("Close") { dismiss() }
                .keyboardShortcut(.cancelAction)
                .disabled(model.isDeleting)
                .accessibilityIdentifier("assetLibrary.close")
            Button(model.deleteTitle, role: .destructive) { confirmsDelete = true }
                .disabled(model.selection.isEmpty || model.isDeleting)
                .accessibilityIdentifier("assetLibrary.delete")
        }
    }
}
