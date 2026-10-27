//
//  InfoPlistKeyCard.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// "Skip the question for every build": the Info.plist key that answers
/// export compliance in the binary, with Copy.
struct InfoPlistKeyCard: View {
    static let snippet = "<key>ITSAppUsesNonExemptEncryption</key>\n<false/>"

    var body: some View {
        Card(padding: Spacing.medium + 2) {
            Text("Skip the question for every build")
                .font(.headline)
            Text("""
            Set this key in the app’s Info.plist, and App Store Connect stops asking for builds that use only exempt encryption. \
            Set it to true instead if they don’t.
            """)
            .font(.callout)
            .foregroundStyle(Palette.label2)
            .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top) {
                // No custom accessibility label: on selectable text it sent
                // SwiftUI's accessibility into endless recursion (a crash).
                Text(Self.snippet)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                Spacer(minLength: Spacing.medium)
                Button(String(localized: "Copy")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(Self.snippet, forType: .string)
                }
                .controlSize(.small)
                .accessibilityLabel(Text("Copy the Info.plist key"))
                .accessibilityIdentifier("appInformation.export.copyKey")
            }
            .padding(Spacing.small + 2)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        }
        .accessibilityIdentifier("appInformation.export.infoPlist")
    }
}

#Preview {
    InfoPlistKeyCard()
        .frame(width: 640)
        .padding()
}
