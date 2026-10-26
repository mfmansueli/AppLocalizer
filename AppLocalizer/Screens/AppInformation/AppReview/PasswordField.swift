//
//  PasswordField.swift
//  AppLocalizer
//

import SwiftUI

/// The demo account's password: masked, with Show / Hide. What's typed
/// goes straight to the Keychain through the view model.
struct PasswordField: View {
    let title: String
    let text: String
    @Binding var isVisible: Bool
    let onChange: @MainActor (String) -> Void

    var body: some View {
        HStack(spacing: Spacing.small) {
            Group {
                if isVisible {
                    TextField(title, text: Binding(get: { text }, set: { onChange($0) }))
                        .accessibilityIdentifier("appInformation.review.password.visible")
                } else {
                    SecureField(title, text: Binding(get: { text }, set: { onChange($0) }))
                        .accessibilityIdentifier("appInformation.review.password")
                }
            }
            .textContentType(.password)
            .labelsHidden()
            .frame(width: 196)
            Button(isVisible ? String(localized: "Hide") : String(localized: "Show")) { isVisible.toggle() }
                .controlSize(.small)
                .accessibilityLabel(Text(isVisible ? "Hide password" : "Show password"))
                .accessibilityIdentifier("appInformation.review.password.show")
        }
    }
}

#Preview {
    @Previewable @State var isVisible = false
    PasswordField(title: "Password", text: "sandbox-2026", isVisible: $isVisible) { _ in }
        .padding()
}
