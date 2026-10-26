//
//  AppInformationViewModel+Review.swift
//  AppLocalizer
//

import Foundation

// App Review: contact, sign-in and notes for the shown version. The
// password goes to the Keychain as you type; changes only carry a
// placeholder for it.
extension AppInformationViewModel {
    /// App Store Connect's review details with the queued ones on top.
    var review: AppReviewValues? {
        guard let content else { return nil }
        let builder = builder
        return builder.review(content.review, with: changes) { [services] in
            try? services.secrets.secret(named: builder.passwordSecretName)
        }
    }

    var isReviewEditable: Bool { content?.isVersionEditable ?? false }

    func setReviewText(_ text: String, for field: AppReviewField) {
        guard var values = review, values.text(field) != text else { return }
        values.setText(text, for: field)
        if field == .password { try? services.secrets.setSecret(text.isEmpty ? nil : text, named: builder.passwordSecretName) }
        queueReview(values, field: field)
    }

    func setSignInRequired(_ required: Bool) {
        guard var values = review, values.signInRequired != required else { return }
        values.signInRequired = required
        queueReview(values, field: .signInRequired)
    }

    /// One change per field, or one `POST` when the version has no review
    /// details yet.
    private func queueReview(_ values: AppReviewValues, field: AppReviewField) {
        guard let content, content.isVersionEditable else { return }
        if content.ids.reviewDetailID == nil {
            apply(builder.newReviewDetailChange(values), id: builder.newReviewDetailChangeID)
        } else {
            apply(builder.reviewFieldChange(field, from: content.review, to: values), id: builder.reviewChangeID(field))
        }
    }
}
