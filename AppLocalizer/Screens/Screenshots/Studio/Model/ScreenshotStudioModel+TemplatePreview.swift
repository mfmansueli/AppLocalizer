//
//  ScreenshotStudioModel+TemplatePreview.swift
//  AppLocalizer
//

import Foundation

/// The guided Look step's template preview: on every device the app ships
/// on (the ones not in the run yet can be added from there), in up to four
/// of its languages, and any screenshot larger in the full-size viewer,
/// where the language switches in place.
extension ScreenshotStudioModel {
    /// The devices a template is previewed on: every one the app ships on,
    /// as What to make offers them.
    func templatePreviewDevices(_ plan: AutopilotPlan) -> [ScreenshotDisplayType] {
        GuidedTemplatePreviewDevices.devices(for: planDevices(plan))
    }

    /// The device picked, else the first one the run makes.
    func templatePreviewDevice(_ plan: AutopilotPlan) -> ScreenshotDisplayType {
        GuidedTemplatePreviewDevices.device(guided.templateDevice, in: templatePreviewDevices(plan), inRun: plan.displayTypes)
    }

    /// Whether the run makes `device`'s screenshots; iPhone always.
    func templatePreviewIsInRun(_ device: ScreenshotDisplayType, plan: AutopilotPlan) -> Bool {
        device == .iPhone || plan.displayTypes.contains(device)
    }

    /// Add … to the Run: the run makes the previewed device's screenshots
    /// too, and the preview stays on it.
    func addTemplatePreviewDevice(_ device: ScreenshotDisplayType) {
        guided.templateDevice = device
        setPlans(device, true)
    }

    /// The language picked, else the primary one.
    func templatePreviewLocale(_ plan: AutopilotPlan) -> String {
        guard let code = guided.templateLocale, plan.localeCodes.contains(code) else { return plan.primaryLocale }
        return code
    }

    /// Up to four languages to preview in, the primary one first.
    func templatePreviewLocales(_ plan: AutopilotPlan) -> [String] {
        GuidedPreviewLocales.pick(from: plan.localeCodes, primary: plan.primaryLocale)
    }

    /// `starter` on the device and in the language picked.
    func templatePreview(_ starter: TemplateStarter, plan: AutopilotPlan) -> GuidedTemplatePreview? {
        screenshots.templatePreview(starter, on: templatePreviewDevice(plan), locale: templatePreviewLocale(plan), plan: plan)
    }

    // MARK: - Viewer

    /// The previewed template's screenshots in the viewer, at `slot`.
    func openTemplatePreview(_ starter: TemplateStarter, plan: AutopilotPlan, at slot: Int) {
        let items = templateViewerItems(starter, plan: plan)
        show(items, at: items.firstIndex { $0.id == Self.templateViewerID(slot) } ?? 0)
        viewerTemplate = viewer == nil ? nil : starter
    }

    /// Shows the viewer's screenshots in `code`, on the same screen; the
    /// Look step's preview follows.
    func setViewerTemplateLocale(_ code: String) {
        guided.templateLocale = code
        guard let starter = viewerTemplate, let plan = run?.plan, let index = viewer?.index else { return }
        viewer = StudioViewer(items: templateViewerItems(starter, plan: plan), index: index)
    }

    /// "Arcade · 3 · Search", "iPhone 6.9″ · 1320 × 2868 · Arabic", and
    /// "· English interface, not captured in this language yet" where the
    /// device's screens aren't captured in the language.
    func templateViewerItems(_ starter: TemplateStarter, plan: AutopilotPlan) -> [StudioViewerItem] {
        guard let preview = templatePreview(starter, plan: plan) else { return [] }
        let primary = StoreLocaleCatalog.locale(code: plan.primaryLocale)?.shortName ?? plan.primaryLocale
        return preview.items.map { item in
            let interface = item.showsPrimaryInterface
                ? String(localized: " · \(primary) interface, not captured in this language yet")
                : ""
            return StudioViewerItem(
                id: Self.templateViewerID(item.slot),
                title: "\(starter.title) · \(item.label)",
                subtitle: "\(preview.sizeTitle) · \(preview.locale.name)" + interface,
                content: .shot(StudioShot(slot: item.slot, name: item.name, image: .render(item.job), pixelSize: item.pixelSize))
            )
        }
    }

    private static func templateViewerID(_ slot: Int) -> String { "template.\(slot)" }
}
