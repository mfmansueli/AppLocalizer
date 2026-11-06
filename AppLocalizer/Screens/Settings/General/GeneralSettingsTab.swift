//
//  GeneralSettingsTab.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → General: the confirmations before pushing or discarding, and
/// the commission used to show proceeds.
struct GeneralSettingsTab: View {
    @Environment(AppPreferences.self) private var preferences

    static let commissionRates: [Double] = [0.15, 0.30]

    var body: some View {
        @Bindable var preferences = preferences
        Form {
            Section("Pushing") {
                LabeledContent {
                    // Segments as wide as their titles, so the row stays one line.
                    FittingSegmentedPicker(
                        label: String(localized: "Confirm before pushing"),
                        options: PushConfirmation.allCases.map { ($0, $0.title) },
                        selection: $preferences.pushConfirmation
                    )
                    .fixedSize()
                    .accessibilityIdentifier("settings.pushConfirmation")
                } label: {
                    SettingsRowLabel(
                        title: "Confirm before pushing",
                        caption: String(localized: "The review sheet always opens first; this adds a final “Push 26 changes?” alert")
                    )
                }
                Toggle("Confirm before discarding changes", isOn: $preferences.confirmsDiscarding)
                    .toggleStyle(.switch)
                Toggle(isOn: $preferences.confirmsPriceIncreases) {
                    SettingsRowLabel(
                        title: "Ask before pushing price increases",
                        caption: String(localized: "Shows how many existing subscribers would be asked to agree")
                    )
                }
                .toggleStyle(.switch)
                .accessibilityIdentifier("settings.confirmsPriceIncreases")
            }
            Section("Screenshot Autopilot") {
                LabeledContent {
                    FittingSegmentedPicker(
                        label: String(localized: "Autopilot"),
                        options: AutopilotFront.allCases.map { ($0, $0.title) },
                        selection: $preferences.autopilotFront
                    )
                    .fixedSize()
                    .accessibilityIdentifier("settings.autopilotFront")
                } label: {
                    SettingsRowLabel(title: "Autopilot", caption: AutopilotFront.note)
                }
            }
            Section("Proceeds") {
                Picker(selection: $preferences.commissionRate) {
                    ForEach(Self.commissionRates, id: \.self) { Text(Self.title(forCommission: $0)).tag($0) }
                } label: {
                    SettingsRowLabel(title: "Apple’s commission used for proceeds", caption: String(localized: "Shown next to customer prices"))
                }
                .accessibilityIdentifier("settings.commission")
            }
        }
        .formStyle(.grouped)
    }

    static func title(forCommission rate: Double) -> String {
        rate < 0.2 ? String(localized: "15% · Small Business Program") : String(localized: "30% · Standard")
    }
}
