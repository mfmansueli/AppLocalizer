//
//  SettingsView.swift
//  AppLocalizer
//

import SwiftUI

/// The Settings window (⌘,). Pricing defaults and translation settings get
/// their own tabs as those features land.
struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("Account", systemImage: "key") {
                AccountSettingsTab()
            }
        }
        .frame(width: 520)
    }
}
