//
//  PrivateKeyDropZone.swift
//  AppLocalizer
//

import SwiftUI

/// The private key row of the connect form: a dashed drop target with a
/// "Choose File…" button while empty, the file's name and a Remove button
/// once a key is imported.
struct PrivateKeyDropZone: View {
    let key: ImportedPrivateKey?
    let onChoose: () -> Void
    let onRemove: () -> Void
    let onDrop: (URL) -> Void

    @State private var isTargeted = false

    var body: some View {
        Group {
            if let key {
                imported(key)
            } else {
                empty
            }
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.horizontal, 14)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isTargeted ? Palette.accent : Palette.dropOutline,
                    style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: key == nil ? [5, 4] : [])
                )
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            onDrop(url)
            return true
        } isTargeted: { isTargeted = $0 }
    }

    private var empty: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.horizontal")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Drop your AuthKey .p8 file here")
                Text("Downloaded once from App Store Connect when the key was created.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Button("Choose File…", action: onChoose)
                .accessibilityIdentifier("connect.chooseKeyButton")
        }
    }

    private func imported(_ key: ImportedPrivateKey) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Palette.positive)
            VStack(alignment: .leading, spacing: 2) {
                Text(key.fileName)
                    .font(.body.monospaced())
                    .accessibilityIdentifier("connect.importedKeyName")
                Text("Private key ready. It stays in this Mac's Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Button("Remove", role: .destructive, action: onRemove)
                .accessibilityIdentifier("connect.removeKeyButton")
        }
    }
}

#Preview {
    VStack {
        PrivateKeyDropZone(key: nil, onChoose: {}, onRemove: {}, onDrop: { _ in })
        PrivateKeyDropZone(key: ImportedPrivateKey(fileName: "AuthKey_2X9R4HXF34.p8", pem: ""), onChoose: {}, onRemove: {}, onDrop: { _ in })
    }
    .padding()
    .frame(width: 520)
}
