//
//  AppRow.swift
//  AppLocalizer
//

import SwiftUI

/// One app in the sidebar: icon tile, name and bundle ID.
struct AppRow: View {
    let app: StoreApp

    var body: some View {
        HStack(spacing: 10) {
            AppIconTile(name: app.name)
            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .lineLimit(1)
                Text(app.bundleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        AppRow(app: StoreApp(id: "1", name: "Bruma", bundleID: "com.lima.bruma"))
        AppRow(app: StoreApp(id: "2", name: "AppLocalizer", bundleID: "com.lima.applocalizer"))
    }
    .frame(width: 260)
}
