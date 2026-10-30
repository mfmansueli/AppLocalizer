//
//  KeyAssistantSetupViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The setup sheet's steps with an API key: the provider, the key and its
/// check, the model and whether translations use it too; what each
/// request may include besides App Store Connect's text; and one test
/// request. Nothing is saved until Done or Finish Without Testing.
@MainActor
@Observable
final class KeyAssistantSetupViewModel {
    let controller: KeyAssistantController
    /// The test's subtitle is for this app.
    let appName: String

    var vendor: AIProviderVendor {
        didSet {
            guard vendor != oldValue else { return }
            keyState = .idle
            models = []
            modelID = nil
        }
    }

    var key = "" {
        didSet { if key != oldValue { keyState = .idle } }
    }

    private(set) var keyState: KeyAssistantKeyState = .idle
    /// What the key can use, once checked.
    private(set) var models: [KeyAssistantModel] = []
    var modelID: KeyAssistantModel.ID?
    var usesKeyForTranslations = true
    var readsProjectFolder = false
    var projectFolder: URL?
    var readsReviews = true
    private(set) var testState: KeyAssistantTestState = .idle

    init(controller: KeyAssistantController, appName: String) {
        self.controller = controller
        self.appName = appName
        let saved = controller.configuration
        vendor = saved?.vendor ?? .anthropic
        if let saved {
            key = controller.savedKey() ?? ""
            models = saved.vendor.assistantModels(available: [saved.model.id])
            modelID = saved.model.id
            keyState = key.isEmpty ? .idle : .works(Self.worksText(saved.vendor, models: models))
            usesKeyForTranslations = saved.usesKeyForTranslations
            readsProjectFolder = saved.readsProjectFolder
            projectFolder = saved.projectFolderPath.map { URL(filePath: ProjectFolderPath.expanded($0)) }
            readsReviews = saved.readsReviews
        }
    }

    // MARK: - Reading

    var model: KeyAssistantModel? {
        models.first { $0.id == modelID } ?? models.first
    }

    /// "~/Developer/Lumen".
    var projectFolderPath: String? {
        projectFolder.map { ProjectFolderPath.abbreviated($0.path) }
    }

    /// "sk-ant-api03-…".
    var keyPlaceholder: String { vendor.keyPrefix + "…" }

    /// The step 2 facts: the Keychain, the bill, the App Store Connect key.
    var keyFacts: [(systemImage: String, text: String)] {
        [
            ("lock", String(localized: "Stored in the Keychain on this Mac. Sent only to \(vendor.title), with each request.")),
            ("creditcard", String(localized: "Billed to your \(vendor.title) account. Before each request you see what will be sent and about how many tokens.")),
            ("checkmark.shield", String(localized: "Your App Store Connect key is never sent.")),
        ]
    }

    // MARK: - Checking and testing

    func checkKey() async {
        keyState = .checking
        let vendor = vendor
        do {
            let models = try await controller.check(key, vendor: vendor)
            guard vendor == self.vendor else { return }
            self.models = models
            if modelID.map({ id in !models.contains { $0.id == id } }) ?? true { modelID = models.first?.id }
            keyState = .works(Self.worksText(vendor, models: models))
        } catch {
            guard vendor == self.vendor else { return }
            keyState = .rejected(error.localizedDescription)
        }
    }

    /// Step 4: one subtitle for the app.
    func runTest() async {
        guard let model else { return }
        testState = .sending
        do {
            let answer = try await controller.test(key: key, vendor: vendor, model: model, appName: appName)
            let seconds = (Double(answer.duration.components.seconds) + Double(answer.duration.components.attoseconds) / 1e18)
                .formatted(.number.precision(.fractionLength(1)))
            testState = .works(String(localized: "\(model.name) answered in \(seconds) s with a subtitle: “\(answer.text)”."))
        } catch {
            testState = .failed(error.localizedDescription)
        }
    }

    /// Done or Finish Without Testing.
    func save() throws {
        guard let model else { return }
        try controller.save(
            KeyAssistantConfiguration(
                vendor: vendor,
                model: model,
                keySuffix: "",
                readsProjectFolder: readsProjectFolder && projectFolder != nil,
                projectFolderPath: projectFolderPath,
                projectFolderBookmark: projectFolder.flatMap(ProjectFolderPicker.bookmark),
                readsReviews: readsReviews,
                usesKeyForTranslations: usesKeyForTranslations
            ),
            key: key
        )
    }

    /// "Key works · 3 models available", or "· models loaded" for a single
    /// recommended one.
    private static func worksText(_ vendor: AIProviderVendor, models: [KeyAssistantModel]) -> String {
        guard vendor == .anthropic else { return String(localized: "Key works · models loaded") }
        return models.count == 1 ? String(localized: "Key works · 1 model available") : String(localized: "Key works · \(models.count) models available")
    }
}
