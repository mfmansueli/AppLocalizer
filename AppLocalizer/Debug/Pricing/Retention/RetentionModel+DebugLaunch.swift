//
//  RetentionModel+DebugLaunch.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

extension RetentionModel {
    /// Brings a Retention DEBUG scene to its starting state through the
    /// calls a person's clicks make. Does nothing outside those scenes.
    func applyDebugLaunch(from services: any RetentionServices, pricing: PricingViewModel) async {
        guard let launch = (services as? DebugRetentionServices)?.launch, let catalog = pricing.catalog else { return }
        store.reset(appID: app.id)
        pricing.page = .retention
        previewEndDate = RetentionSampleData.endDate
        for draft in launch.drafts {
            store.keep(draft, appID: app.id, queued: false)
        }
        await load(subscriptions: RetentionSubscription.all(in: catalog))
        await loadLibrary()
        if let id = launch.selectedMessageID ?? messages.first?.id, let message = messages.first(where: { $0.id == id }) {
            select(message)
        }
        if let kind = launch.kind { setKind(kind) }
        if let image = launch.image { edit { $0.image = image } }
        selectedLocale = launch.locale
        showsAllLanguages = launch.showsAllLanguages
        isAdvancedExpanded = launch.isAdvancedExpanded
        isDarkPreview = launch.isDark
        if let suggestion = launch.suggestion { store.suggest(suggestion, appID: app.id) }
        if launch.queues { toggleQueue() }
        switch launch.sheet {
        case .offer:
            isOfferSheetPresented = true
        case let .image(picked):
            chooseImage()
            pickedImageID = picked
        case nil:
            break
        }
    }
}
#endif
