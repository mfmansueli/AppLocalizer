//
//  MockLumenCard.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// A white rounded card of the mock interface.
struct MockLumenCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockLumenPalette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
#endif
