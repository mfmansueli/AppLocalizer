//
//  YesNoPicker.swift
//  AppLocalizer
//

import SwiftUI

/// A compact Yes | No segmented picker. Neither segment is selected while
/// the question hasn't been answered.
struct YesNoPicker: View {
    let title: String
    let value: Bool?
    let onSet: @MainActor (Bool) -> Void

    var body: some View {
        Picker(title, selection: Binding(get: { value }, set: { newValue in newValue.map(onSet) })) {
            Text("Yes").tag(Bool?.some(true))
            Text("No").tag(Bool?.some(false))
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .accessibilityLabel(Text(title))
    }
}

#Preview {
    VStack {
        YesNoPicker(title: "Third-party content", value: false) { _ in }
        YesNoPicker(title: "Uses encryption", value: nil) { _ in }
    }
    .padding()
}
