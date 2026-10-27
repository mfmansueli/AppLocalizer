//
//  NoVersionView.swift
//  AppLocalizer
//

import SwiftUI

/// "No version to edit": only the live version exists, so version texts
/// can't change until a new version is created in App Store Connect. The
/// app-level fields stay editable, through "View Version 1.3".
struct NoVersionView: View {
    let viewModel: StorePageViewModel

    var body: some View {
        let live = viewModel.content?.version.versionString ?? ""
        VStack(spacing: Spacing.small) {
            Image(systemName: "doc")
                .font(.system(size: 26))
                .foregroundStyle(Palette.label3)
                .accessibilityHidden(true)
            Text("No version to edit")
                .font(.title3.weight(.semibold))
            Text("Version \(live) is live and read-only. To change What’s New, the description, keywords and other version texts, create version \(Self.nextVersion(after: live)) in App Store Connect, then refresh.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
            Text("Name, Subtitle and Privacy Policy URL are app-level and stay editable.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
            HStack(spacing: Spacing.small) {
                Link(destination: Self.appStoreConnectURL(appID: viewModel.app.id)) {
                    Text("Open App Store Connect")
                }
                .buttonStyle(.borderedProminent)
                Button("View Version \(live)") {
                    viewModel.showsReadOnlyVersion = true
                }
                .accessibilityIdentifier("storePage.viewLiveVersion")
            }
            .padding(.top, Spacing.xxSmall)
        }
        .padding(Spacing.xxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.noVersion")
    }

    /// "1.4" after "1.3", "2.0.1" after "2.0.0": the last number plus one.
    static func nextVersion(after version: String) -> String {
        var parts = version.split(separator: ".").map(String.init)
        guard let last = parts.last, let number = Int(last) else { return version }
        parts[parts.count - 1] = String(number + 1)
        return parts.joined(separator: ".")
    }

    static func appStoreConnectURL(appID: StoreApp.ID) -> URL {
        URL(string: "https://appstoreconnect.apple.com/apps/\(appID)/distribution") ?? URL(filePath: "/")
    }
}
