//
//  MockLumenPlaceholder.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// A grey bar standing in for body text in the mock interface.
struct MockLumenPlaceholder: View {
    var width: CGFloat
    var height: CGFloat = 7

    var body: some View {
        Capsule()
            .fill(MockLumenPalette.placeholder)
            .frame(width: width, height: height)
    }
}
#endif
