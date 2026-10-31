//
//  StudioHeader.swift
//  AppLocalizer
//

import SwiftUI

/// "Screenshots", the version line, and the device, language and
/// Live · New controls. Many languages go in a menu.
struct StudioHeader: View {
    @Bindable var studio: ScreenshotStudioModel
    @Bindable var screenshots: ScreenshotsViewModel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                titles
                Spacer(minLength: Spacing.medium)
                controls
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                titles
                controls
            }
        }
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: Spacing.tiny) {
            Text("Screenshots")
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(studio.subtitle)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .accessibilityIdentifier("studio.subtitle")
        }
        .fixedSize()
    }

    private var controls: some View {
        HStack(spacing: Spacing.small) {
            StudioSegmentedControl(
                label: String(localized: "Device"),
                options: studio.devices.map { .init(value: $0, title: $0.title, key: $0.rawValue) },
                selection: $studio.device,
                identifier: "studio.device"
            )
            languages
            StudioSegmentedControl(
                label: String(localized: "Set"),
                options: StudioSetChoice.allCases.map { .init(value: $0, title: $0.title, isEnabled: $0 == .live || studio.hasNewSet, key: $0.rawValue) },
                selection: setChoice,
                identifier: "studio.set"
            )
            .help(helpText)
        }
    }

    @ViewBuilder
    private var languages: some View {
        if studio.locales.count <= 5 {
            StudioSegmentedControl(
                label: String(localized: "Language"),
                options: studio.locales.map { .init(value: $0.code, title: $0.shortName, key: $0.code) },
                selection: $studio.selectedLocale,
                identifier: "studio.language"
            )
        } else {
            Picker(String(localized: "Language"), selection: $studio.selectedLocale) {
                ForEach(studio.locales) { locale in
                    Text(locale.name).tag(locale.code)
                }
            }
            .labelsHidden()
            .fixedSize()
            .accessibilityIdentifier("studio.language")
        }
    }

    /// Shows Live while there's no new set, without forgetting New.
    private var setChoice: Binding<StudioSetChoice> {
        Binding {
            studio.builder.effectiveChoice
        } set: {
            studio.choice = $0
        }
    }

    private var helpText: Text {
        if studio.hasNewSet { return Text("Live is on the App Store; New waits in Review & Push") }
        return Text("New is available while a new set waits in Review & Push")
    }
}
