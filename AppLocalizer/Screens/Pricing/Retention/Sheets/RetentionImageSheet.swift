//
//  RetentionImageSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Image for the message: the Asset Library's images, the ones that fit
/// Apple's rules first (the others say why not), and Make One with Claude
/// Design… for a new one.
struct RetentionImageSheet: View {
    let model: RetentionModel

    private let columns = [GridItem(.flexible(), spacing: Spacing.small), GridItem(.flexible(), spacing: Spacing.small)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Image for the message")
                    .font(.title2.weight(.semibold))
                Text("From the Asset Library. PNG, 3840 wide, 160 to 2160 tall, no transparency. Apple shows it in light and dark.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding([.horizontal, .top], Spacing.xLarge)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    library
                    makeOne
                }
                .padding(Spacing.xLarge)
            }
            .frame(maxHeight: 460)
            Divider()
            footer
        }
        .frame(width: 620)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("retention.imageSheet")
    }

    @ViewBuilder
    private var library: some View {
        switch model.libraryState {
        case .idle, .loading:
            HStack(spacing: Spacing.small) {
                ProgressView().controlSize(.small)
                Text("Reading the Asset Library…").foregroundStyle(Palette.label2)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        case let .failed(message):
            VStack(spacing: Spacing.small) {
                Text("AppLocalizer couldn’t read the Asset Library: \(message)")
                    .foregroundStyle(Palette.label2)
                Button("Try Again") { Task { await model.loadLibrary() } }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        case .loaded:
            if model.libraryImages.isEmpty {
                Text("The Asset Library has no images yet.")
                    .foregroundStyle(Palette.label2)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                LazyVGrid(columns: columns, spacing: Spacing.small) {
                    ForEach(model.libraryImages) { image in
                        tile(image)
                    }
                }
            }
        }
    }

    private func tile(_ image: RetentionImage) -> some View {
        let isPicked = model.pickedImageID == image.id
        return Button {
            model.pickedImageID = image.id
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                RetentionArtworkView(image: image)
                    .aspectRatio(CGFloat(max(1, image.pixelWidth)) / CGFloat(max(1, image.pixelHeight)), contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                HStack {
                    Text(image.name)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    if isPicked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Palette.accent)
                            .accessibilityHidden(true)
                    }
                }
                Text(image.problems.first?.message ?? image.detail)
                    .font(.caption)
                    .foregroundStyle(image.fits ? Palette.label2 : Palette.danger)
                    .lineLimit(2)
            }
            .padding(Spacing.xSmall)
            .background(isPicked ? Palette.accentTint : .clear, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                    .strokeBorder(isPicked ? Palette.accent : Palette.separator2, lineWidth: isPicked ? 2 : 0.5)
            }
            .contentShape(Rectangle())
            .opacity(image.fits ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!image.fits)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isPicked ? .isSelected : [])
        .accessibilityIdentifier("retention.imageSheet.image.\(image.name)")
    }

    private var makeOne: some View {
        HStack(spacing: Spacing.small) {
            Text("Need one? Claude Design draws it in the app’s design language at 3840 × 1000; it joins the Asset Library when you push.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            RetentionAskButton(app: model.app, kind: .image(message: model.selectedMessage?.referenceName ?? ""))
        }
        .padding(Spacing.medium)
        .background(Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
    }

    private var footer: some View {
        let picked = model.libraryImages.first { $0.id == model.pickedImageID }
        return HStack(spacing: Spacing.small) {
            Spacer()
            Button("Cancel") { model.isImageSheetPresented = false }
                .keyboardShortcut(.cancelAction)
            Button("Use This Image") { if let picked { model.useImage(picked) } }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(picked?.fits != true)
                .accessibilityIdentifier("retention.imageSheet.use")
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }
}
