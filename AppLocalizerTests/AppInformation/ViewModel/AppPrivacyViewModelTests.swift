//
//  AppPrivacyViewModelTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The App Privacy page's view model on the sample services: edits going
/// to the worksheet store, the scan prompt, import, the privacy URLs
/// queuing Store Page's and App Information's changes, and Mark as
/// Published. The pasteboard is replaced; nothing leaves the test.
@MainActor
@Suite("AppPrivacyViewModel")
struct AppPrivacyViewModelTests {
    private typealias Support = PrivacyTestSupport
    private let queue = ChangeQueue()
    private let app = StoreApp(id: DebugFixtures.AppID.lumen, name: "Lumen Journal", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")

    private func model(_ worksheet: PrivacyWorksheet = PrivacyWorksheet()) -> (AppInformationViewModel, AppPrivacyViewModel) {
        let section = AppInformationViewModel(app: app, services: DebugAppInformationServices(privacy: worksheet), queue: queue)
        section.privacy.copy = { _ in }
        section.privacy.now = { Support.date }
        return (section, section.privacy)
    }

    @Test func editsGoThroughTheStore() {
        let (_, privacy) = model()
        #expect(privacy.status == .notStarted)
        privacy.setCollects(true)
        privacy.setCollected(.email, true)
        privacy.togglePurpose(.analytics, for: .email)
        privacy.setLinked(.email, true)
        let stored = privacy.services.privacy.worksheet(for: app.id)
        #expect(stored[.email]?.answer == Support.collected([.appFunctionality, .analytics], linked: true))
        #expect(privacy.status == .done)
        #expect(privacy.collectedSummary(for: .contactInfo) == "1 collected")
        #expect(privacy.collectedSummary(for: .location) == "None collected")
    }

    @Test func copyPromptWaitsForTheScan() {
        let (_, privacy) = model()
        var copied: [String] = []
        privacy.copy = { copied.append($0) }
        #expect(!privacy.isWaitingForScan)
        privacy.copyPrompt()
        #expect(copied == [privacy.scanPrompt])
        #expect(privacy.scanPrompt.contains("Lumen Journal (dev.example.lumen)"))
        #expect(privacy.isWaitingForScan)
        privacy.update { $0.beginScan(by: Support.client, at: Support.date) }
        #expect(!privacy.isWaitingForScan)
        #expect(privacy.runningScan?.assistant == Support.client)
    }

    @Test func acceptAllHighConfidenceSaysWhatItLeft() {
        let (section, privacy) = model(DebugPrivacyWorksheets.scanning(at: Support.date))
        let count = privacy.highConfidenceCount
        #expect(count > 0)
        privacy.acceptAllHighConfidence()
        #expect(privacy.highConfidenceCount == 0)
        #expect(section.toast?.hasPrefix("Accepted \(count) high-confidence suggestions") == true)
    }

    @Test func theFiltersAndHiddenCounts() {
        let (_, privacy) = model(DebugPrivacyWorksheets.review)
        #expect(privacy.title(of: .unreviewed).hasPrefix("Unreviewed · "))
        #expect(privacy.title(of: .all) == PrivacyWorksheetFilter.all.title)
        let shown = privacy.visibleCategories.flatMap(\.types)
        #expect(shown.contains(.purchases))
        #expect(privacy.hiddenCount(in: .contactInfo) > 0)
        privacy.showsAllTypes = true
        #expect(privacy.visibleCategories.flatMap(\.types).count == 35)
        #expect(privacy.hiddenCount(in: .contactInfo) == 0)
    }

    @Test func importingAFastlaneFile() {
        let (section, privacy) = model()
        privacy.showImport(
            DebugPrivacyWorksheets.fastlaneFile,
            fileName: "app_privacy_details.json",
            path: "~/Developer/Lumen/fastlane/app_privacy_details.json"
        )
        #expect(privacy.isImportSheetPresented)
        #expect(privacy.importPreview?.types.count == 5)
        privacy.confirmImport()
        #expect(!privacy.isImportSheetPresented)
        #expect(privacy.worksheet.reviewedAnswers.collectedTypes.count == 5)
        #expect(privacy.worksheet[.email]?.status == .yours)
        #expect(section.toast?.hasPrefix("Imported 5 data types") == true)
    }

    @Test func anUnreadableFileSaysWhy() {
        let (_, privacy) = model()
        privacy.showImport(Data("{}".utf8), fileName: "notes.json")
        #expect(privacy.isImportSheetPresented)
        #expect(privacy.importPreview == nil)
        #expect(privacy.importError == PrivacyFastlaneCoder.Failure.notFastlane.localizedDescription)
        privacy.cancelImport()
        #expect(!privacy.isImportSheetPresented)
    }

    @Test func exportUsesReviewedAnswers() throws {
        let (_, privacy) = model(DebugPrivacyWorksheets.done)
        let data = try privacy.exportData(as: .fastlane)
        #expect(try data == (PrivacyFastlaneCoder.encode(privacy.worksheet.reviewedAnswers)))
        privacy.exportFormat = .markdown
        #expect(privacy.exportPreview.hasPrefix("# Lumen Journal · App Privacy answers"))
        #expect(privacy.exportFileName == "Lumen Journal App Privacy.md")
        privacy.saveExport()
        #expect(privacy.isExporterPresented)
        #expect(!privacy.isExportSheetPresented)
    }

    @Test func theChecklistMarksPublished() {
        let (section, privacy) = model(DebugPrivacyWorksheets.done)
        #expect(!privacy.worksheet.allStepsChecked)
        for step in privacy.steps {
            privacy.setChecked(step, true)
        }
        #expect(privacy.progressText == "\(privacy.steps.count) of \(privacy.steps.count) steps")
        #expect(privacy.canMarkPublished)
        privacy.markPublished()
        #expect(privacy.status == .published(Support.date))
        #expect(!privacy.canMarkPublished)
        #expect(privacy.publishedText != nil)
        #expect(section.toast != nil)
    }

    @Test func copyingAStepPutsItsTextOnThePasteboard() throws {
        let (_, privacy) = model(DebugPrivacyWorksheets.done)
        var copied: [String] = []
        privacy.copy = { copied.append($0) }
        let step = try #require(privacy.steps.first)
        privacy.copyStep(step)
        #expect(copied == ["Data collection: Yes, we collect data from this app"])
        #expect(privacy.copiedStepID == step.id)
    }

    @Test func aPolicyURLEditQueuesStorePagesChange() async throws {
        let (section, privacy) = model()
        await privacy.loadURLs()
        let table = try #require(privacy.urlsTable)
        #expect(table.locales.count == StoreLocaleCatalog.all.count)
        #expect(table.missingPolicyLocales == [.frenchCanada, .hebrew, .hindi])

        privacy.setPolicyURL(.frenchCanada, to: "https://lumen.example/fr/confidentialite")
        let change = try #require(queue.changes.first)
        #expect(change.section == .storePage)
        #expect(change.id.hasSuffix(".fr-CA.privacyPolicyUrl"))
        #expect(section.hasPendingChanges(on: .appPrivacy))
        #expect(privacy.urlsTable?.isPolicyPending(.frenchCanada) == true)

        privacy.setPolicyURL(.frenchCanada, to: "")
        #expect(queue.changes.isEmpty)
    }

    @Test func fillMissingUsesThePrimaryLocalesURL() async {
        let (section, privacy) = model()
        await privacy.loadURLs()
        privacy.fillMissingPolicyURLs()
        #expect(queue.changes.count == 3)
        #expect(privacy.urlsTable?.missingPolicyLocales.isEmpty == true)
        #expect(privacy.urlsCoverageText?.hasPrefix("Privacy Policy URL \(StoreLocaleCatalog.all.count) of") == true)
        #expect(section.toast?.hasPrefix("Filled 3 locales") == true)
    }

    @Test func aChoicesURLEditQueuesAnAppInformationChange() async throws {
        let (section, privacy) = model()
        await privacy.loadURLs()
        privacy.setChoicesURL(.german, to: "https://lumen.example/de/choices")
        let change = try #require(queue.changes.first)
        #expect(change.section == .appInformation)
        #expect(section.hasPendingChanges(on: .appPrivacy))
        #expect(!section.hasPendingChanges(on: .general))
    }

    @Test func aFailedURLLoadSaysSo() async {
        var services = DebugAppInformationServices(privacy: PrivacyWorksheet())
        services.privacyURLsError = .server(statusCode: 500, detail: nil)
        let section = AppInformationViewModel(app: app, services: services, queue: queue)
        await section.privacy.loadURLs()
        #expect(section.privacy.urls.errorMessage != nil)
        #expect(section.privacy.urlsTable == nil)
    }

    @Test func anIntentOpensAPageAndTab() {
        let section = AppInformationViewModel(app: app, services: DebugAppInformationServices(), queue: ChangeQueue())
        #expect(section.handle(.openAppInformationPage(.appPrivacy, privacyTab: .urls)))
        #expect(section.page == .appPrivacy)
        #expect(section.privacy.tab == .urls)
        #expect(!section.handle(.showResults))
    }
}
#endif
