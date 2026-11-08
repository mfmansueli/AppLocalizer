//
//  RetentionPreview.swift
//  AppLocalizer
//

import SwiftUI

/// The preview column: Light | Dark, the phone with the selected
/// language's message, and a note that Apple's words come from the system.
struct RetentionPreview: View {
    let model: RetentionModel
    let message: RetentionMessage

    var body: some View {
        @Bindable var model = model
        VStack(spacing: Spacing.small) {
            RetentionSegmentedControl(
                label: String(localized: "Preview appearance"),
                segments: [
                    RetentionSegment(value: false, title: String(localized: "Light"), identifier: "retention.preview.light"),
                    RetentionSegment(value: true, title: String(localized: "Dark"), identifier: "retention.preview.dark"),
                ],
                selection: $model.isDarkPreview,
                identifier: "retention.preview.appearance"
            )
            phone
            Text(note)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("retention.preview")
    }

    private var phone: some View {
        let code = model.selectedLocale
        let strings = RetentionCancelStrings.strings(for: code)
        let text = message.text(for: code)
        return RetentionPhone(
            app: model.app,
            strings: strings,
            endText: strings.endText(date: model.previewEndDate, code: code),
            header: text.header,
            messageBody: text.body,
            image: message.kind == .image ? message.image : nil,
            offer: message.kind == .offer ? offer(strings: strings) : nil,
            isDark: model.isDarkPreview,
            isRightToLeft: RetentionCancelStrings.isRightToLeft(code)
        )
    }

    /// The best offer Apple might show: the first of the first subscription's.
    private func offer(strings: RetentionCancelStrings) -> (group: String, line: String)? {
        for id in message.subscriptionIDs {
            guard let offer = model.offers(for: id).first, let subscription = model.content.subscription(id: id) else { continue }
            return (subscription.groupName, strings.offerLine(offer, basePrice: subscription.basePrice, period: subscription.period))
        }
        return nil
    }

    private var note: String {
        var note = String(localized: "Apple’s own words around your message are shown by the system in each language.")
        if message.kind == .offer { note += " " + String(localized: "People who aren’t eligible for an offer see the message alone.") }
        return note
    }
}
