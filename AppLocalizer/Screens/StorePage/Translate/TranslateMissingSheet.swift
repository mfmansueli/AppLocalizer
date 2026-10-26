//
//  TranslateMissingSheet.swift
//  AppLocalizer
//

import SwiftUI

/// "Translate missing fields": the provider, tone, terms not to translate,
/// which fields, and the locales with how many fields each. Translate
/// closes the sheet and runs the batch in the progress banner.
struct TranslateMissingSheet: View {
    let viewModel: StorePageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newTerm = ""

    private var translation: TranslateMissingViewModel { viewModel.translation }

    var body: some View {
        @Bindable var translation = translation
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(translation.isSendingWhatsNew ? "Send What’s New to every locale" : "Translate missing fields")
                    .font(.title2.weight(.semibold))
                Text(translation.selectedPlan.summary)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.label2)
            }
            .padding([.horizontal, .top], Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    providers
                    if let message = translation.provider.setupMessage {
                        Banner(kind: .rateLimited, title: message) {
                            SettingsLink {
                                Text("Open Settings…")
                            }
                        }
                        .padding(.horizontal, -Spacing.large)
                        .padding(.vertical, -Spacing.small)
                        .accessibilityIdentifier("storePage.translate.setup")
                    }
                    toneAndGlossary
                    availabilityMessages
                    locales
                    Text("You accept or reject each suggestion. Accepted text stays tagged “machine-translated” until someone reviews it.")
                        .font(.caption2)
                        .foregroundStyle(Palette.label2)
                }
                .padding(.horizontal, Spacing.xLarge)
                .padding(.bottom, Spacing.medium)
            }
            Divider()
            HStack(spacing: Spacing.small) {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(translation.startTitle) {
                    viewModel.startTranslation()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!translation.canStart)
                .accessibilityIdentifier("storePage.translate.start")
            }
            .padding(Spacing.large)
        }
        .frame(width: 640, height: 680)
        .task { await translation.checkAvailability() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.translateSheet")
    }

    private var providers: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            sectionTitle("Provider")
            VStack(spacing: 0) {
                ForEach(TranslationProvider.allCases) { provider in
                    TranslateProviderRow(provider: provider, isSelected: translation.provider == provider) {
                        translation.provider = provider
                    }
                    if provider != TranslationProvider.allCases.last {
                        Divider()
                    }
                }
            }
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Translation provider"))
        }
    }

    private var toneAndGlossary: some View {
        @Bindable var translation = translation
        return HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                sectionTitle("Tone")
                Picker("Tone", selection: $translation.glossary.tone) {
                    ForEach(TranslationTone.allCases) { tone in
                        Text(tone.title).tag(tone)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                sectionTitle("Fields")
                    .padding(.top, Spacing.xxSmall)
                Picker("Fields", selection: $translation.field) {
                    Text("Every field in scope").tag(ListingField?.none)
                    Divider()
                    ForEach(translation.fieldOptions) { field in
                        Text(field.title).tag(Optional(field))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Text("Fields"))
                .accessibilityIdentifier("storePage.translate.field")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                sectionTitle("Don’t translate")
                FlowLayout(spacing: Spacing.xxSmall) {
                    ForEach(translation.glossary.terms, id: \.self) { term in
                        GlossaryTermChip(term: term) {
                            translation.glossary.remove(term)
                        }
                    }
                    TextField("Add term", text: $newTerm)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.small)
                        .frame(width: 100)
                        .onSubmit {
                            translation.glossary.add(newTerm)
                            newTerm = ""
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var availabilityMessages: some View {
        if translation.provider == .appleTranslation {
            let needed = translation.localesNeedingDownload
            if !needed.isEmpty {
                HStack(spacing: Spacing.small) {
                    InlineMessage.warning(
                        String(localized: "Apple Translation needs to download \(ListFormatter.localizedString(byJoining: needed.map(\.name))) first.")
                    )
                    Spacer(minLength: Spacing.small)
                    LanguageDownloadButton(source: translation.plan.sourceLocale, targets: needed) {
                        await translation.checkAvailability()
                    }
                }
                .accessibilityIdentifier("storePage.translate.download")
            }
            let unsupported = translation.unsupportedLocales
            if !unsupported.isEmpty {
                InlineMessage.error(
                    String(localized: "Apple Translation can’t translate into \(ListFormatter.localizedString(byJoining: unsupported.map(\.name))).")
                )
            }
        }
    }

    private var locales: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            sectionTitle("Locales")
            let plan = translation.plan
            VStack(spacing: 0) {
                ForEach(plan.locales) { locale in
                    Toggle(isOn: Binding {
                        translation.isIncluded(locale)
                    } set: {
                        translation.setIncluded(locale, $0)
                    }) {
                        HStack {
                            Text(locale.name)
                                .font(.callout)
                            Spacer()
                            Text(fieldCount(plan.itemCount(in: locale)))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(Palette.label2)
                        }
                    }
                    .toggleStyle(.checkbox)
                    .padding(.horizontal, Spacing.medium)
                    .frame(minHeight: 32)
                    .accessibilityIdentifier("storePage.translate.locale.\(locale.code)")
                    if locale != plan.locales.last {
                        Divider()
                    }
                }
                if plan.isEmpty {
                    Text("Nothing to translate: every field in scope has text.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .padding(Spacing.medium)
                }
            }
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        }
    }

    private func fieldCount(_ count: Int) -> String {
        count == 1 ? String(localized: "1 field") : String(localized: "\(count) fields")
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .textCase(.uppercase)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Palette.label2)
    }
}
