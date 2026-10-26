//
//  ActivitySheet.swift
//  AppLocalizer
//

import SwiftUI

/// Activity: every push, newest first, with what succeeded and failed.
struct ActivitySheet: View {
    let apps: [StoreApp]

    @Environment(PushHistory.self) private var history
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Activity")
                .font(.title2.weight(.semibold))
                .padding(Spacing.xLarge)
            Divider()
            if history.records.isEmpty {
                ContentUnavailableView("Nothing pushed yet", systemImage: "clock", description: Text("Your pushes will show here."))
            } else {
                List(history.records) { record in
                    VStack(alignment: .leading) {
                        Text(record.appName).font(.headline)
                        Text(record.title).foregroundStyle(Palette.label2)
                    }
                }
            }
            Divider()
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(Spacing.large)
        }
        .frame(width: 640, height: 520)
        .accessibilityIdentifier("activity.sheet")
    }
}
