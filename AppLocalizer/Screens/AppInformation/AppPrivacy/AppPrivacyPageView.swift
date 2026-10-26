//
//  AppPrivacyPageView.swift
//  AppLocalizer
//

import SwiftUI

/// App Privacy: one honest line until the worksheet arrives. The
/// questionnaire has no App Store Connect API, so it will never be pushed.
struct AppPrivacyPageView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            AppInformationPageHeader(
                title: AppInformationPage.appPrivacy.title,
                subtitle: String(localized: "What the app collects and why, as App Store Connect’s privacy questionnaire asks it.")
            )
            Label(
                String(localized: """
                Coming soon: a worksheet an assistant helps fill from the code, and a checklist for entering it in App Store Connect, \
                which has no API for this questionnaire.
                """),
                systemImage: "hammer"
            )
            .font(.callout)
            .foregroundStyle(Palette.label2)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("appInformation.appPrivacy.coming")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy")
    }
}

#Preview {
    AppPrivacyPageView()
        .padding()
        .frame(width: 640)
}
