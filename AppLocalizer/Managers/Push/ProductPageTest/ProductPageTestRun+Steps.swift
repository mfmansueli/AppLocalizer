//
//  ProductPageTestRun+Steps.swift
//  AppLocalizer
//

import Foundation

extension ProductPageTestRun {
    /// Every step, and how it ended.
    func makeTest() async -> ProductPageTestOutcome {
        guard environment.placesThroughAPI else {
            let place = ExtrasPushKind.name(ofPlacementType: request.placement.placementType)
            return export(because: String(localized: "App Store Connect’s API can’t put \(place) on a test’s treatment."))
        }
        let tester = environment.tester
        let request = request
        do {
            step = .checkingTests
            let tests = try await call { try await tester.productPageExperiments(appID: request.appID) }
            let platform = ProductPageExperimentRequests.platform
            if let current = tests.first(where: { !$0.isFinished && ($0.platform ?? platform) == platform }) {
                return .testInProgress(name: current.name, state: current.stateTitle)
            }
            step = .creatingTest
            let experiment: ProductPageExperiment
            do {
                experiment = try await call {
                    try await tester.createProductPageExperiment(appID: request.appID, name: request.testName, trafficProportion: request.trafficProportion)
                }
            } catch let error as AppStoreConnectError where error.isStateError {
                // A draft or a running test the list didn't show.
                return .testInProgress(name: nil, state: String(localized: "in progress"))
            }
            return await fill(experiment)
        } catch {
            stopRemaining()
            return .failed(Self.text(for: error) + " " + String(localized: "Nothing was created."))
        }
    }

    /// The treatment and each language's variant on it, then the start
    /// if asked. A draft that ends up empty is deleted.
    private func fill(_ experiment: ProductPageExperiment) async -> ProductPageTestOutcome {
        let tester = environment.tester
        let request = request
        do {
            step = .creatingTreatment
            let treatment = try await call { try await tester.createProductPageTreatment(experimentID: experiment.id, name: request.treatmentName) }
            step = .placing
            var placed: [String] = []
            var failed: [String: String] = [:]
            for locale in request.locales {
                do {
                    try await place(locale, on: treatment)
                    placed.append(locale.locale)
                } catch let failure as ProductPageTestFailure {
                    localeStatuses[locale.locale] = .failed(failure.text)
                    // The first refusal means treatments don't take this
                    // artwork: the test can't be made here.
                    if case .placementRefused = failure, placed.isEmpty {
                        stopRemaining()
                        let removal = await removeDraft(experiment)
                        return export(because: [failure.text, removal].joined(separator: " "))
                    }
                    failed[locale.locale] = failure.text
                } catch where Self.stopsTheRest(error) {
                    localeStatuses[locale.locale] = .failed(Self.text(for: error))
                    throw error
                } catch {
                    localeStatuses[locale.locale] = .failed(Self.text(for: error))
                    failed[locale.locale] = Self.text(for: error)
                }
            }
            guard !placed.isEmpty else {
                let removal = await removeDraft(experiment)
                return .failed(String(localized: "No language’s variant went on the treatment.") + " " + removal)
            }
            var created = ProductPageTestCreated(
                experimentID: experiment.id, treatmentID: treatment.id, name: experiment.name ?? request.testName,
                placement: request.placement, treatmentName: request.treatmentName, placedLocales: placed, failedLocales: failed
            )
            if request.startsTest {
                step = .starting
                do {
                    try await call { try await tester.startProductPageExperiment(id: experiment.id) }
                    created.isStarted = true
                } catch {
                    created.startFailure = Self.describe(error)
                }
            }
            return .created(created)
        } catch {
            stopRemaining()
            let removal = await removeDraft(experiment)
            return .failed(Self.text(for: error) + " " + removal)
        }
    }

    /// One language: the treatment's page in it, the variant uploaded and
    /// processed, then placed in each group that takes its size.
    private func place(_ locale: ProductPageTestLocale, on treatment: ProductPageTreatment) async throws {
        let tester = environment.tester
        let placementType = request.placement.placementType
        localeStatuses[locale.locale] = .uploading(0)
        let groups = try await groups(for: locale)
        let localization = try await call {
            try await tester.createProductPageTreatmentLocalization(treatmentID: treatment.id, locale: locale.locale)
        }
        let asset = try await processedAsset(for: locale)
        localeStatuses[locale.locale] = .placing
        var placementIDs: [String] = []
        for group in groups {
            do {
                let placement = try await call {
                    try await tester.createProductPageTreatmentPlacement(
                        placementType: placementType, placementGroup: group, asset: asset, treatmentLocalizationID: localization.id
                    )
                }
                placementIDs.append(placement.id)
            } catch let error as AppStoreConnectError where Self.isRefusal(error) {
                throw ProductPageTestFailure.placementRefused(placementType: placementType, detail: error.pushFailureText)
            }
        }
        localeStatuses[locale.locale] = .done(assetID: asset.id, placementIDs: placementIDs)
    }

    /// Deletes a draft that couldn't be finished, so it doesn't block the
    /// next test; the sentence saying how that went.
    private func removeDraft(_ experiment: ProductPageExperiment) async -> String {
        step = .removingDraft
        let tester = environment.tester
        do {
            try await call { try await tester.deleteProductPageExperiment(id: experiment.id) }
            return String(localized: "The unfinished draft was deleted.")
        } catch {
            let name = experiment.name ?? request.testName
            return String(localized: "The unfinished draft “\(name)” couldn’t be deleted (\(Self.describe(error))): delete it in App Store Connect before making another test.")
        }
    }

    /// Both variants to the request's folder, with the steps to make the
    /// test by hand.
    private func export(because reason: String) -> ProductPageTestOutcome {
        step = .exporting
        do {
            let result = try ProductPageTestExport(request: request).write()
            return .exported(result, reason: reason)
        } catch {
            return .failed(reason + " " + String(localized: "Exporting both variants failed too (\(error.localizedDescription)). The test wasn’t created."))
        }
    }

    /// Languages not tried yet when the run stops.
    private func stopRemaining() {
        for (locale, status) in localeStatuses where status == .waiting {
            localeStatuses[locale] = .cancelled
        }
    }
}
