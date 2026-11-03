//
//  ProductPageTestSheet.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// “Test with Product Page Optimization…”: the current header or search
/// image (“Interface”) against a variant with one idea changed
/// (“Outcome”). AppLocalizer asks the run's design source for the variant,
/// renders and checks it in every language, then makes the test as a draft
/// through the API, or exports both variants and says what to do in App
/// Store Connect. Results are App Store Connect's: there's no results view
/// here.
struct ProductPageTestSheet: View {
    @Bindable var model: ProductPageTestModel
    let center: AutopilotCenter?

    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Test with Product Page Optimization").font(.title3.weight(.semibold))
                Text("\(model.placement.title) · \(model.plan.appName)").font(.callout).foregroundStyle(Palette.label2)
            }
            Text(ProductPageTestModel.explanation)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("ppo.explanation")
            comparison
            if model.controlWaits {
                Banner(
                    kind: .info,
                    title: String(localized: "Push the current \(model.placement.title.lowercased()) image first."),
                    message: String(localized: "The test compares the treatment with what your page shows now.")
                )
                .padding(.horizontal, -Spacing.large)
                .accessibilityIdentifier("ppo.controlWaits")
            }
            phaseContent
            if let notice = model.notice {
                Text(notice).font(.callout).foregroundStyle(Palette.label2).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("ppo.notice")
            }
            footer
        }
        .padding(Spacing.large)
        .frame(width: 660)
        .task(id: center?.run(for: model.plan.appID)?.variantRequest) { await model.reload() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ppo.sheet")
    }

    // MARK: - Interface vs Outcome

    private var comparison: some View {
        let primary = model.rows.first
        return HStack(alignment: .top, spacing: Spacing.medium) {
            variantColumn(
                name: model.controlName, role: String(localized: "Current page"),
                meaning: ArtworkVariantRequest.meaning(of: model.controlName), url: primary?.control
            )
            variantColumn(
                name: model.treatmentName, role: String(localized: "Treatment"),
                meaning: model.variant?.change ?? ArtworkVariantRequest.meaning(of: model.treatmentName), url: primary?.treatment
            )
        }
    }

    private func variantColumn(name: String, role: String, meaning: String, url: URL?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ExtrasFileThumbnail(url: url, pixelSize: model.kind.pixelSize, width: 300)
            Text("\(name) · \(role)").font(.callout.weight(.semibold))
            Text(meaning.prefix(1).uppercased() + meaning.dropFirst())
                .font(.caption).foregroundStyle(Palette.label2).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Steps

    @ViewBuilder
    private var phaseContent: some View {
        switch model.phase {
        case .intro:
            EmptyView()
        case .asking:
            HStack(spacing: Spacing.small) {
                ProgressView().controlSize(.small)
                Text("Waiting for \(model.assistantName ?? String(localized: "the assistant"))’s \(model.treatmentName) variant…")
                    .font(.callout)
            }
            .accessibilityIdentifier("ppo.waiting")
        case .variantReady:
            languages
        case .testing:
            testing
        case .finished:
            outcome
        }
    }

    private var languages: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(model.rows) { row in
                    HStack(alignment: .top, spacing: Spacing.small) {
                        Text(row.name).font(.callout).frame(width: 150, alignment: .leading)
                        ExtrasFileThumbnail(url: row.treatment, pixelSize: model.kind.pixelSize, width: 120)
                        if row.checks.isEmpty {
                            Text(row.treatment == nil ? String(localized: "Not rendered") : String(localized: "Passes every check"))
                                .font(.caption).foregroundStyle(Palette.label2)
                        } else {
                            ArtworkCheckPills(checks: row.checks)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, Spacing.xSmall)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("ppo.row.\(row.locale)")
                    Divider()
                }
            }
        }
        .frame(maxHeight: 220)
    }

    private var testing: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(spacing: Spacing.small) {
                ProgressView().controlSize(.small)
                Text(model.run?.step?.title ?? model.run?.title ?? "").font(.callout)
            }
            ForEach(model.rows) { row in
                HStack {
                    Text(row.name).font(.caption)
                    Spacer()
                    Text(model.run?.status(of: row.locale).title ?? "").font(.caption).foregroundStyle(Palette.label2)
                }
            }
        }
        .accessibilityIdentifier("ppo.testing")
    }

    @ViewBuilder
    private var outcome: some View {
        if let outcome = model.run?.outcome {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Label(outcome.title, systemImage: outcome.isCreated ? "checkmark.circle.fill" : "info.circle")
                    .font(.headline)
                    .foregroundStyle(outcome.isCreated ? Palette.positive : Palette.label)
                Text(outcome.detail).font(.callout).foregroundStyle(Palette.label2).fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("ppo.outcome")
        }
    }

    // MARK: - Buttons

    private var footer: some View {
        HStack(spacing: Spacing.small) {
            if case let .exported(result, _) = model.run?.outcome {
                Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting(result.files.isEmpty ? [result.folder] : result.files) }
                    .accessibilityIdentifier("ppo.showInFinder")
            }
            Spacer()
            Button(model.phase == .finished ? String(localized: "Done") : String(localized: "Close")) { dismiss() }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("ppo.close")
            switch model.phase {
            case .intro:
                Button("Ask for the \(model.treatmentName) Variant") {
                    Task { await model.ask(center: center, launcher: launcher) }
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("ppo.ask")
            case .asking:
                Button("Cancel Request") { model.cancelAsking(center: center) }
                    .accessibilityIdentifier("ppo.cancelAsk")
            case .variantReady:
                Button("Ask for Another") {
                    Task { await model.ask(center: center, launcher: launcher) }
                }
                .accessibilityIdentifier("ppo.askAgain")
                Button("Create Test") { model.createTest() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.canCreateTest)
                    .help(model.createBlockReason ?? String(localized: "Makes the test as a draft; you start it in App Store Connect."))
                    .accessibilityIdentifier("ppo.create")
            case .testing, .finished:
                EmptyView()
            }
        }
    }
}
