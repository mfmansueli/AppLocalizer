//
//  ScreenshotsViewModel+TemplatePreview.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsViewModel {
    /// `starter` laid out on `device` in `code` with the set's captions and
    /// captures, for the guided Look step's preview; nil until the set is
    /// read. Nothing is rendered here.
    func templatePreview(_ starter: TemplateStarter, on device: ScreenshotDisplayType, locale code: String, plan: AutopilotPlan) -> GuidedTemplatePreview? {
        guard let document else { return nil }
        let primary = context.primaryLocale
        let locale = code == primary.code ? primary : locales.first { $0.code == code } ?? StoreLocaleCatalog.locale(code: code) ?? primary
        let builder = GuidedTemplatePreviewBuilder(
            document: document, plan: plan, appID: app.id, appName: app.name, primary: primary,
            engine: layoutEngine, sampleCaptions: Self.sampleCaptions
        )
        return builder.preview(starter, on: device, locale: locale)
    }

    /// Looks up the App Store rating where `starter`'s laurels show, so the
    /// preview leaves them out where the app has no ratings yet, as the set
    /// will, instead of showing the template's sample "4.9". All ten slots:
    /// a laurel can be on a slot the set doesn't have yet (Cinema's 2nd).
    func lookUpRatings(for starter: TemplateStarter) {
        lookUpRatings(for: ScreenshotTemplate.starter(starter, id: app.id, title: app.name, slotCount: ScreenshotTemplate.maximumSlots))
    }

    /// Looks up the 5-star App Store reviews `starter`'s Reviews slot
    /// quotes (Social Proof), so the preview shows them, or says there are
    /// none to show yet (Bruma, not on the App Store).
    func lookUpReviews(for starter: TemplateStarter) {
        lookUpReviews(for: ScreenshotTemplate.starter(starter, id: app.id, title: app.name, slotCount: ScreenshotTemplate.maximumSlots))
    }
}
