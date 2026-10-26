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

    /// DEBUG scenes open AI Assistants on the pairing sheet or the log.
    private let opensPairing: Bool
    private let scrollsToLog: Bool

    init(selection: SettingsTab = .account, opensPairing: Bool = false, scrollsToLog: Bool = false) {
        _selection = State(initialValue: selection)
        self.opensPairing = opensPairing
        self.scrollsToLog = scrollsToLog
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
            Tab("AI Assistants", systemImage: "apple.terminal", value: .assistants) {
                AssistantsSettingsTab(opensPairing: opensPairing, scrollsToLog: scrollsToLog)
            }
            Tab("General", systemImage: "gearshape", value: .general) {
                GeneralSettingsTab()
            }
        }
        .frame(width: 760, height: 610)
    }
}
