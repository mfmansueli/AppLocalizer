//
//  CategoryPicker.swift
//  AppLocalizer
//

import SwiftUI

/// A pop-up of App Store categories. An ID App Store Connect returned that
/// isn't in the list still shows, under its own name.
struct CategoryPicker: View {
    let title: String
    let selection: String?
    let categories: [AppCategory]
    /// Offers "None" first, for optional categories.
    var allowsNone = false
    let onSelect: @MainActor (String?) -> Void

    var body: some View {
        Picker(title, selection: Binding(get: { selection }, set: onSelect)) {
            if allowsNone || selection == nil {
                Text("None").tag(String?.none)
                Divider()
            }
            ForEach(options) { category in
                Text(category.name).tag(String?.some(category.id))
            }
        }
        .labelsHidden()
        .frame(width: 180)
        .accessibilityLabel(Text(title))
    }

    private var options: [AppCategory] {
        guard let selection, !categories.contains(where: { $0.id == selection }) else { return categories }
        return categories + [AppCategory(id: selection, name: AppCategory.name(for: selection))]
    }
}

#Preview {
    CategoryPicker(title: "Primary", selection: "LIFESTYLE", categories: AppCategory.all) { _ in }
        .padding()
}
