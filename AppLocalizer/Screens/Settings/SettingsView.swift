//
//  SettingsView.swift
//  AppLocalizer
//

import SwiftUI

/// The Settings window (⌘,): saved keys, pricing defaults, translation and
/// general confirmations. Every tab edits shared objects from the
/// environment (`AppSession`, `AppPreferences`, `TranslationPreferences`), so
/// changes reach the main window at once.
struct SettingsView: View {
    @State private var selection: SettingsTab
    @Environment(AppSession.self) private var session
    @Environment(\.keyChecker) private var keyChecker

    init(selection: SettingsTab = .account) {
        _selection = State(initialValue: selection)
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Account", systemImage: "key.horizontal", value: .account) {
                AccountSettingsTab(viewModel: AccountSettingsViewModel(session: session, checker: keyChecker))
            }
            Tab("Pricing", systemImage: "tag", value: .pricing) {
                PricingSettingsTab()
            }
            Tab("Translation", systemImage: "globe", value: .translation) {
                TranslationSettingsTab()
            }
            Tab("General", systemImage: "gearshape", value: .general) {
                GeneralSettingsTab()
            }
        }
        .frame(width: 760, height: 610)
    }
}
