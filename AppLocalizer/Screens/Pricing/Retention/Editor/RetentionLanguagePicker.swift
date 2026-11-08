//
//  RetentionLanguagePicker.swift
//  AppLocalizer
//

import SwiftUI

/// The language being edited: the first five (and the selected one when
/// it's further down), a dot on any that runs too long, and All 18
/// languages for the rest.
struct RetentionLanguagePicker: View {
    let model: RetentionModel
    let message: RetentionMessage

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Language")
                .font(.callout)
                .foregroundStyle(Palette.label2)
            RetentionSegmentedControl(
                label: String(localized: "Language"),
                segments: shown.map { locale in
                    let isTooLong = message.text(for: locale.code).isTooLong
                    return RetentionSegment(
                        value: locale.code,
                        title: RetentionLanguages.shortName(of: locale, among: model.languages),
                        hasWarning: isTooLong,
                        accessibilityNote: isTooLong ? String(localized: "too long") : nil,
                        identifier: "retention.language.\(locale.code)"
                    )
                },
                selection: $model.selectedLocale,
                identifier: "retention.languages"
            )
            Button(allLanguagesTitle) {
                withAnimation(.snappy) { model.showsAllLanguages.toggle() }
            }
            .buttonStyle(.link)
            .font(.callout)
            .accessibilityIdentifier("retention.allLanguages")
        }
    }

    private var allLanguagesTitle: String {
        model.showsAllLanguages ? String(localized: "Hide the list") : String(localized: "All \(model.languages.count) languages")
    }

    private var shown: [StoreLocale] {
        var locales = Array(model.languages.prefix(RetentionLanguages.pickerCount))
        if !locales.contains(where: { $0.code == model.selectedLocale }),
           let selected = model.languages.first(where: { $0.code == model.selectedLocale })
        {
            locales.append(selected)
        }
        return locales
    }
}
