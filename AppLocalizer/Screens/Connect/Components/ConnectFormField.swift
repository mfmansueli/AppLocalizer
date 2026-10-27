//
//  ConnectFormField.swift
//  AppLocalizer
//

import SwiftUI

/// One labeled text field of the connect form, monospaced, with a red
/// outline and its hint underneath while the value is malformed.
struct ConnectFormField: View {
    let title: LocalizedStringKey
    @Binding var text: String
    let prompt: String
    var width: CGFloat?
    let issue: CredentialsIssue?
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            TextField(title, text: $text, prompt: Text(prompt))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .font(.body.monospaced())
                .autocorrectionDisabled()
                .frame(width: width)
                .overlay {
                    if issue != nil {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(Palette.dangerMark, lineWidth: 1.5)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityIdentifier(identifier)
            if let issue {
                Label {
                    Text(issue.message)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.circle")
                }
                .font(.footnote)
                .foregroundStyle(Palette.danger)
                .accessibilityIdentifier("\(identifier).issue")
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        ConnectFormField(title: "Issuer ID", text: .constant("69a6de7f-3c2e-47e3"), prompt: "", issue: .invalidIssuerID, identifier: "a")
        ConnectFormField(title: "Key ID", text: .constant(""), prompt: "2X9R4HXF34", width: 160, issue: nil, identifier: "b")
    }
    .padding()
    .frame(width: 480)
}
