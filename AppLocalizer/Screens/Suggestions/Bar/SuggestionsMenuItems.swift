//
//  SuggestionsMenuItems.swift
//  AppLocalizer
//

import SwiftUI

/// The less-used suggestion controls, in a section's More menu: which
/// sources to show, only the fields with something to decide, Dismiss All
/// and bringing dismissed ones back.
struct SuggestionsMenuItems: View {
    let model: SuggestionBarModel
    @Binding var filter: SuggestionSourceFilter
    @Binding var showsOnlyFields: Bool
    /// "Only fields with suggestions or changes", where there are fields.
    var showsFieldsToggle = true
    let onDismissAll: () -> Void
    let onRestore: () -> Void

    var body: some View {
        Section("Suggestions") {
            Picker("Show Suggestions From", selection: $filter) {
                ForEach(model.segments) { segment in
                    Text(model.segmentTitle(segment)).tag(segment)
                }
            }
            .accessibilityIdentifier("suggestions.sourceFilter")
            if showsFieldsToggle {
                Toggle("Only Fields with Suggestions or Changes", isOn: $showsOnlyFields)
                    .accessibilityIdentifier("suggestions.onlyFields")
            }
            Button("Dismiss All Here", action: onDismissAll)
                .disabled(model.visibleCount == 0)
                .accessibilityIdentifier("suggestions.dismissAll")
            if model.dismissedCount > 0 {
                Button(String(localized: "Restore \(model.dismissedCount) Dismissed"), action: onRestore)
                    .accessibilityIdentifier("suggestions.restore")
            }
        }
    }
}
