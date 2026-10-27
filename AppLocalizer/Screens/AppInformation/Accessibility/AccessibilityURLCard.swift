//
//  AccessibilityURLCard.swift
//  AppLocalizer
//

import SwiftUI

/// The accessibility URL: one optional https address for the app, not
/// localized, on the product page of every device except Apple TV.
struct AccessibilityURLCard: View {
    let url: String
    let problem: String?
    let onChange: @MainActor (String) -> Void

    var body: some View {
        Card(padding: Spacing.medium + 2) {
            Text("\(Text("Accessibility URL").fontWeight(.semibold))\(Text(" · optional · one for the app, not localized").foregroundStyle(Palette.label2))")
                .font(.caption)
                .accessibilityHidden(true)
            TextField(String(localized: "Accessibility URL"), text: Binding(get: { url }, set: { onChange($0) }), prompt: Text(verbatim: "https://example.com/accessibility"))
                .textFieldStyle(.roundedBorder)
                .textContentType(.URL)
                .overlay {
                    if problem != nil {
                        RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(Palette.dangerMark, lineWidth: 1.5)
                    }
                }
                .accessibilityLabel(Text("Accessibility URL"))
                .accessibilityValue(Text(problem ?? url))
                .accessibilityIdentifier("appInformation.accessibility.url")
            if let problem {
                Text(problem)
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
                    .accessibilityIdentifier("appInformation.accessibility.urlProblem")
            }
            Text("Shown on the product page on every device except Apple TV. Publishing it is immediate once a version is live.")
                .font(.caption2)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("appInformation.accessibility.urlCard")
    }
}

#Preview {
    VStack {
        AccessibilityURLCard(url: "https://lumen.example/accessibility", problem: nil) { _ in }
        AccessibilityURLCard(url: "lumen.example/accessibility", problem: AccessibilityURLValidator.problem(in: "lumen.example")) { _ in }
    }
    .frame(width: 700)
    .padding()
}
