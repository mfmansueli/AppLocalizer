//
//  ReviewPushSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Review & Push (⇧⌘P): every pending change grouped by app and section,
/// each as old → new with its source and a discard button.
struct ReviewPushSheet: View {
    let selectedAppID: StoreApp.ID?
    let apps: [StoreApp]

    @Environment(ChangeQueue.self) private var changes
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Review changes")
                .font(.title2.weight(.semibold))
                .padding(Spacing.xLarge)
            Divider()
            if changes.changes.isEmpty {
                ContentUnavailableView(
                    "Nothing to push",
                    systemImage: "checkmark.circle",
                    description: Text("Edits in Pricing, Store Page and App Information collect here until you push them.")
                )
            } else {
                List {
                    ForEach(changes.changes) { change in
                        HStack {
                            Text(change.title)
                            Spacer()
                            Text("\(change.oldValue) → \(change.newValue)")
                                .monospacedDigit()
                            Button {
                                changes.discard(id: change.id)
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(Text("Discard"))
                        }
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
        .frame(width: 800, height: 600)
        .accessibilityIdentifier("review.sheet")
    }
}
