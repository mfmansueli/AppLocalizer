//
//  AppWorkspaceView.swift
//  AppLocalizer
//

import SwiftUI

/// The detail column for the selected app: a section picker in the toolbar
/// (subscription pricing / store page) and that section's content. Both
/// sections are placeholders until the design handoff.
struct AppWorkspaceView: View {
    let app: StoreApp
    @Binding var section: AppWorkspaceSection

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(section.title)
            } icon: {
                Image(systemName: section.systemImage)
            }
        } description: {
            Text(section.summary)
        }
        .accessibilityIdentifier("workspace.placeholder.\(section.rawValue)")
        .navigationTitle(app.name)
        .navigationSubtitle(subtitle)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Section", selection: $section) {
                    ForEach(AppWorkspaceSection.allCases) { section in
                        Label {
                            Text(section.title)
                        } icon: {
                            Image(systemName: section.systemImage)
                        }
                        .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .labelStyle(.titleOnly)
                .accessibilityIdentifier("workspace.sectionPicker")
            }
        }
    }

    private var subtitle: String {
        [app.bundleID, app.primaryLocale].compactMap(\.self).joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        AppWorkspaceView(
            app: StoreApp(id: "1", name: "Bruma", bundleID: "com.lima.bruma", primaryLocale: "en-US"),
            section: .constant(.subscriptionPricing)
        )
    }
    .frame(width: 900, height: 600)
}
