//
//  WorkspaceCommands.swift
//  AppLocalizer
//

import SwiftUI

/// Menu bar commands for the main window: sections (⌘1–⌘4) and Refresh (⌘R)
/// in View, a Push menu with Review & Push (⇧⌘P) and Activity, plus the
/// section-specific commands that work through `WorkspaceIntent`.
struct WorkspaceCommands: Commands {
    @FocusedValue(\.workspaceNavigator) private var navigator

    var body: some Commands {
        CommandGroup(before: .toolbar) {
            ForEach(AppWorkspaceSection.allCases) { section in
                Button(section.title) { navigator?.open(section) }
                    .keyboardShortcut(KeyEquivalent(section.shortcutDigit))
            }
            .disabled(navigator == nil)
            Divider()
            Button("Refresh") { navigator?.refresh() }
                .keyboardShortcut("r")
                .disabled(navigator == nil)
            Divider()
        }
        CommandGroup(after: .textEditing) {
            Button("Find") { navigator?.send(.search) }
                .keyboardShortcut("f")
                .disabled(navigator == nil)
            Button("Find and Replace Across Locales…") { navigator?.open(.storePage, intent: .findAndReplace) }
                .keyboardShortcut("f", modifiers: [.command, .option])
                .disabled(navigator == nil)
        }
        CommandMenu("Pricing") {
            Group {
                Button("Review Suggestions") { navigator?.open(.subscriptionPricing, intent: .reviewSuggestions) }
                Button("Apply Recommended Prices…") { navigator?.open(.subscriptionPricing, intent: .applyRecommendedPrices) }
                Button("Results") { navigator?.open(.subscriptionPricing, intent: .showResults) }
            }
            .disabled(navigator == nil)
        }
        CommandMenu("Store Page") {
            Group {
                Button("Translate Missing…") { navigator?.open(.storePage, intent: .translateMissing) }
                    .keyboardShortcut("t", modifiers: [.command, .shift])
                Button("Import Translations…") { navigator?.open(.storePage, intent: .importTranslations) }
                    .keyboardShortcut("i", modifiers: [.command, .shift])
            }
            .disabled(navigator == nil)
        }
        CommandMenu("Push") {
            Group {
                Button("Review & Push…") { navigator?.isReviewPresented = true }
                    .keyboardShortcut("p", modifiers: [.command, .shift])
                Button("Activity") { navigator?.isActivityPresented = true }
            }
            .disabled(navigator == nil)
        }
    }
}
