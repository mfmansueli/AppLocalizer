//
//  PrivateKeyDropZone.swift
//  AppLocalizer
//

import SwiftUI

/// The private key part of the connect form: a dashed drop target with
/// "or Choose File…" while empty, "Release to import" while a file hovers,
/// the file's name and Remove once a key is imported, or why a dropped
/// file isn't a `.p8` key with Choose Again….
struct PrivateKeyDropZone: View {
    let key: ImportedPrivateKey?
    /// A picked or dropped file that isn't a private key.
    let rejectedFileName: String?
    let onChoose: () -> Void
    let onRemove: () -> Void
    let onDrop: (URL) -> Void

    @State private var isTargeted: Bool

    /// `isTargeted` starts the zone in its hover state, for DEBUG scenes.
    init(
        key: ImportedPrivateKey?,
        rejectedFileName: String? = nil,
        isTargeted: Bool = false,
        onChoose: @escaping () -> Void,
        onRemove: @escaping () -> Void,
        onDrop: @escaping (URL) -> Void
    ) {
        self.key = key
        self.rejectedFileName = rejectedFileName
        self.onChoose = onChoose
        self.onRemove = onRemove
        self.onDrop = onDrop
        _isTargeted = State(initialValue: isTargeted)
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(background, in: shape)
            .overlay { shape.strokeBorder(borderColor, style: border) }
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first else { return false }
                onDrop(url)
                return true
            } isTargeted: { isTargeted = $0 }
            .animation(.easeOut(duration: 0.12), value: isTargeted)
    }

    @ViewBuilder
    private var content: some View {
        if isTargeted {
            hover
        } else if let key {
            imported(key)
        } else if let rejectedFileName {
            rejected(rejectedFileName)
        } else {
            empty
        }
    }

    private var empty: some View {
        VStack(spacing: Spacing.xSmall) {
            Image(systemName: "key.horizontal")
                .foregroundStyle(Palette.label2)
                .accessibilityHidden(true)
            Text("Drop \(Text(verbatim: "AuthKey_XXXXXXXXXX.p8").monospaced()) here")
                .font(.callout)
            Button("or Choose File…", action: onChoose)
                .buttonStyle(.link)
                .font(.footnote)
                .accessibilityIdentifier("connect.chooseKeyButton")
        }
        .padding(.vertical, Spacing.xLarge)
    }

    private var hover: some View {
        VStack(spacing: Spacing.xSmall) {
            Image(systemName: "square.and.arrow.down")
                .font(.title3)
                .accessibilityHidden(true)
            Text("Release to import")
                .font(.callout.weight(.semibold))
        }
        .foregroundStyle(Palette.accentText)
        .padding(.vertical, Spacing.xLarge + 3)
    }

    private func imported(_ key: ImportedPrivateKey) -> some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: "key.horizontal.fill")
                .font(.footnote)
                .foregroundStyle(Palette.label)
                .frame(width: 36, height: 36)
                .background(Palette.fill2, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(key.fileName)
                    .font(.callout.monospaced().weight(.semibold))
                    .accessibilityIdentifier("connect.importedKeyName")
                Label("Stays in this Mac’s Keychain", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            Spacer(minLength: Spacing.medium)
            Button("Remove", action: onRemove)
                .controlSize(.small)
                .accessibilityIdentifier("connect.removeKeyButton")
        }
        .padding(Spacing.medium)
    }

    private func rejected(_ fileName: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(Palette.dangerMark)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(Text(verbatim: fileName).monospaced().bold()) isn’t a .p8 private key")
                    .font(.callout.weight(.semibold))
                Text(CredentialsIssue.unreadablePrivateKey.message)
                    .font(.footnote)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Spacing.small)
            Button("Choose Again…", action: onChoose)
                .controlSize(.small)
                .accessibilityIdentifier("connect.chooseAgainButton")
        }
        .padding(Spacing.medium)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connect.rejectedFile")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
    }

    private var background: Color {
        if isTargeted { return Palette.accentTint }
        if key == nil, rejectedFileName != nil { return Palette.dangerTint }
        return Palette.fill1
    }

    private var borderColor: Color {
        if isTargeted { return Palette.accent }
        if key == nil, rejectedFileName != nil { return Palette.dangerMark.opacity(0.7) }
        return key == nil ? Palette.dropOutline : Palette.separator
    }

    private var border: StrokeStyle {
        StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: key == nil && rejectedFileName == nil ? [5, 4] : [])
    }
}

#Preview {
    VStack {
        PrivateKeyDropZone(key: nil, onChoose: {}, onRemove: {}, onDrop: { _ in })
        PrivateKeyDropZone(key: nil, isTargeted: true, onChoose: {}, onRemove: {}, onDrop: { _ in })
        PrivateKeyDropZone(key: ImportedPrivateKey(fileName: "AuthKey_2X9R4HXF34.p8", pem: ""), onChoose: {}, onRemove: {}, onDrop: { _ in })
        PrivateKeyDropZone(key: nil, rejectedFileName: "notes.txt", onChoose: {}, onRemove: {}, onDrop: { _ in })
    }
    .padding()
    .frame(width: 470)
}
