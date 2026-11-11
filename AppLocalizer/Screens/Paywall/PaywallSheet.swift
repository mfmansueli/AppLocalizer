//
//  PaywallSheet.swift
//  AppLocalizer
//

import SwiftUI

/// The paywall: on the left what Pro adds, with the feature the person
/// clicked highlighted; on the right what was blocked in their own
/// numbers, the plans (Yearly with its trial selected), a button that says
/// exactly what happens, and the full price, how renewal works, Restore
/// Purchases, Terms of Use and Privacy Policy, always in view. Close is
/// always there.
struct PaywallSheet: View {
    @Bindable var model: PaywallModel
    let onClose: (_ continues: Bool) -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 0) {
            PaywallFeatureList(highlighted: model.context.feature)
            ZStack(alignment: .topTrailing) {
                Group {
                    switch model.phase {
                    case .plans, .buying: plans
                    case .compare: compare
                    case .done: PaywallDoneView(model: model, onClose: onClose)
                    }
                }
                .padding(.init(top: 24, leading: 28, bottom: 18, trailing: 28))
                Button {
                    onClose(false)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.label2)
                .keyboardShortcut(model.phase == .done ? nil : .cancelAction)
                .help("Close")
                .accessibilityLabel(Text("Close"))
                .accessibilityIdentifier("paywall.close")
                .padding(Spacing.medium)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.window)
        }
        .frame(width: PaywallStyle.sheetSize.width, height: PaywallStyle.sheetSize.height)
        .task { await model.load() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("paywall.sheet")
    }

    // MARK: - Plans

    private var plans: some View {
        VStack(alignment: .leading, spacing: Spacing.small + 2) {
            if let title = model.context.title, let detail = model.context.detail {
                contextCard(title: title, detail: detail)
            }
            Text("Choose a plan")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            planList
            HStack(alignment: .top, spacing: Spacing.small) {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Palette.positive)
                    .accessibilityHidden(true)
                Text("""
                **Free stays free.** Editing and pushing every language yourself, built-in checks, suggestions one at a time \
                and Review & Push, for one app.
                """)
                .font(.system(size: 12))
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("paywall.freeStaysFree")
            Spacer(minLength: 0)
            buyButton
            links
        }
    }

    private func contextCard(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.small + 2) {
            Image(systemName: "lock.fill")
                .foregroundStyle(Palette.machineTranslated)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .accessibilityIdentifier("paywall.context.title")
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("paywall.context.detail")
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small + 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.machineTranslatedTint, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        // Clear of Close.
        .padding(.trailing, 30)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("paywall.context")
    }

    @ViewBuilder
    private var planList: some View {
        if model.offers.isEmpty {
            if let problem = model.offersProblem {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    InlineMessage.error(problem)
                    Button("Try Again") {
                        Task { await model.load() }
                    }
                    .accessibilityIdentifier("paywall.retry")
                }
                .accessibilityIdentifier("paywall.offersProblem")
            } else {
                HStack(spacing: Spacing.small) {
                    ProgressView().controlSize(.small)
                    Text("Asking the App Store for the plans…").font(.callout).foregroundStyle(Palette.label2)
                }
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            }
        } else {
            VStack(spacing: Spacing.small) {
                ForEach(model.offers) { offer in
                    PaywallPlanRow(offer: offer, tag: model.tag(for: offer), isSelected: model.plan == offer.plan) {
                        model.plan = offer.plan
                    }
                }
            }
            .disabled(model.phase == .buying)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Plan"))
            .accessibilityIdentifier("paywall.plans")
        }
    }

    /// The button, then the full price and how renewal works.
    private var buyButton: some View {
        VStack(spacing: Spacing.xSmall) {
            Button {
                Task { await model.buy() }
            } label: {
                Text(model.callToAction)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 28)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!model.canBuy)
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("paywall.buy")
            if let message = model.message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("paywall.message")
            }
            if let finePrint = model.finePrint {
                Text(finePrint)
                    .font(.footnote)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("paywall.finePrint")
            }
        }
    }

    private var links: some View {
        HStack(spacing: Spacing.xSmall) {
            Button("Restore Purchases") {
                Task { await model.restore() }
            }
            .accessibilityIdentifier("paywall.restore")
            Text(verbatim: "·").accessibilityHidden(true)
            Button("Compare Free and Pro") { model.showCompare(true) }
                .accessibilityIdentifier("paywall.compareButton")
            if let terms = ProLinks.termsOfUse {
                Text(verbatim: "·").accessibilityHidden(true)
                Button("Terms of Use") { openURL(terms) }
                    .accessibilityIdentifier("paywall.terms")
            }
            if let privacy = ProLinks.privacyPolicy {
                Text(verbatim: "·").accessibilityHidden(true)
                Button("Privacy Policy") { openURL(privacy) }
                    .accessibilityIdentifier("paywall.privacy")
            }
        }
        .buttonStyle(.link)
        .font(.system(size: 11.5))
        .foregroundStyle(Palette.label3)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Compare

    private var compare: some View {
        VStack(alignment: .leading, spacing: Spacing.small + 2) {
            HStack(spacing: Spacing.small) {
                Button {
                    model.showCompare(false)
                } label: {
                    Label("Plans", systemImage: "chevron.left")
                }
                .controlSize(.small)
                .accessibilityIdentifier("paywall.backToPlans")
                Text("Free and Pro")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.trailing, 36)
            ScrollView {
                PaywallCompareTable()
            }
            buyButton
        }
    }
}
