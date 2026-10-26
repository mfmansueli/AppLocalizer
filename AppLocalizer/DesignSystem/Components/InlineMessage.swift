//
//  InlineMessage.swift
//  AppLocalizer
//

import SwiftUI

/// A one-line status under a field or form: an SF Symbol plus text, tinted
/// by role. Use the `.error` / `.warning` helpers rather than the init.
struct InlineMessage: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.callout)
        .foregroundStyle(tint)
    }

    static func error(_ text: String) -> InlineMessage {
        InlineMessage(text: text, systemImage: "exclamationmark.octagon.fill", tint: Palette.danger)
    }

    static func warning(_ text: String) -> InlineMessage {
        InlineMessage(text: text, systemImage: "exclamationmark.triangle.fill", tint: Palette.warning)
    }
}

#Preview {
    VStack(alignment: .leading) {
        InlineMessage.error("App Store Connect rejected this API key.")
        InlineMessage.warning("The saved key couldn't be read.")
    }
    .padding()
}
