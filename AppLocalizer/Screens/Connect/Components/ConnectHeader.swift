//
//  ConnectHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The top of the connect form: the app's tile, the title and one line on
/// what the key is for.
struct ConnectHeader: View {
    let title: LocalizedStringKey

    private static let tileColors = [Color(red: 0.24, green: 0.55, blue: 1), Color(red: 0.07, green: 0.36, blue: 0.86)]

    var body: some View {
        VStack(spacing: Spacing.small) {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(LinearGradient(colors: Self.tileColors, startPoint: .top, endPoint: .bottom))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "globe")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.accentColor.opacity(0.35), radius: 10, y: 3)
                .padding(.bottom, Spacing.xSmall)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 24))
                .accessibilityAddTraits(.isHeader)
            Text("AppLocalizer uses an App Store Connect API key to read your apps and push prices and store text.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
    }
}

#Preview {
    ConnectHeader(title: "Connect to App Store Connect")
        .padding()
}
