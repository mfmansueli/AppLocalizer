//
//  AssetLibraryFileRow.swift
//  AppLocalizer
//

import SwiftUI

/// One file in the library sheet: its checkbox (off and locked while a
/// page shows it), a thumbnail, its names, size, date and state, and
/// whether it's on a page, or why it couldn't be deleted.
struct AssetLibraryFileRow: View {
    let file: AssetLibraryFile
    let model: AssetLibraryModel

    private static let thumbnailWidth: CGFloat = 72

    var body: some View {
        HStack(spacing: Spacing.small) {
            Toggle(isOn: Binding(get: { model.selection.contains(file.id) }, set: { _ in model.toggle(file) })) { EmptyView() }
                .toggleStyle(.checkbox)
                .labelsHidden()
                .disabled(!model.canSelect(file))
                .help(model.canSelect(file) ? "" : String(localized: "A page shows it: take it off the page before deleting it."))
                .accessibilityLabel(Text("Select \(file.title)"))
                .accessibilityIdentifier("assetLibrary.check.\(file.id)")
            thumbnail
            VStack(alignment: .leading, spacing: 2) {
                Text(file.title)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(details)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let error = model.deleteErrors[file.id] {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Palette.danger)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("assetLibrary.error.\(file.id)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            placement
        }
        .padding(.vertical, 6)
        .padding(.horizontal, Spacing.small)
        .contentShape(Rectangle())
        .onTapGesture { model.toggle(file) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assetLibrary.row.\(file.id)")
    }

    private var thumbnail: some View {
        AsyncImage(url: file.thumbnailURL(width: Self.thumbnailWidth)) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit()
            } else {
                Image(systemName: file.media == .video ? "film" : "photo")
                    .foregroundStyle(Palette.label3)
            }
        }
        .frame(width: Self.thumbnailWidth, height: 44)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .accessibilityHidden(true)
    }

    /// "header-en-US-loop.mov · 4.9 MB · Nov 3, 22:39 · Ready".
    private var details: String {
        var parts: [String] = []
        if let fileName = file.fileName, fileName != file.title { parts.append(fileName) }
        if let size = file.fileSize { parts.append(Int64(size).formatted(.byteCount(style: .file))) }
        if let date = file.createdDate { parts.append(date.formatted(date: .abbreviated, time: .shortened)) }
        parts.append(file.stateTitle)
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private var placement: some View {
        if model.deletingID == file.id {
            ProgressView().controlSize(.small)
        } else {
            Text(model.placementTitle(of: file))
                .font(.caption)
                .foregroundStyle(model.isUnused(file) ? Palette.label : Palette.label2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(model.isUnused(file) ? Palette.fill2 : .clear, in: Capsule())
                .accessibilityIdentifier("assetLibrary.placement.\(file.id)")
        }
    }
}
