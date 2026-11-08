//
//  RetentionOfferSheet.swift
//  AppLocalizer
//

import SwiftUI

/// New retention offer: a name only the person sees, the subscription,
/// free, pay as you go or pay up front, how long, and the U.S. price
/// (Apple's equalized price everywhere else). Add Offer queues it.
struct RetentionOfferSheet: View {
    let subscriptions: [RetentionSubscription]
    let problems: (RetentionOfferDraft) -> [RetentionOfferProblem]
    let onCancel: () -> Void
    let onAdd: (RetentionOfferDraft) -> Void

    @State private var draft: RetentionOfferDraft

    init(
        subscriptions: [RetentionSubscription],
        initial: RetentionOfferDraft,
        problems: @escaping (RetentionOfferDraft) -> [RetentionOfferProblem],
        onCancel: @escaping () -> Void,
        onAdd: @escaping (RetentionOfferDraft) -> Void
    ) {
        self.subscriptions = subscriptions
        self.problems = problems
        self.onCancel = onCancel
        self.onAdd = onAdd
        _draft = State(initialValue: initial)
    }

    private var subscription: RetentionSubscription? {
        subscriptions.first { $0.id == draft.subscriptionID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("New retention offer")
                    .font(.title2.weight(.semibold))
                Text("Shown only to people about to cancel. Apple decides who’s eligible, and shows each person the best of your offers for that subscription.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding([.horizontal, .top], Spacing.xLarge)
            VStack(alignment: .leading, spacing: Spacing.medium) {
                rows
                if let subscription {
                    Text("\(draft.summary(for: subscription)) Other countries get Apple’s equalized price; change any of them later in Prices.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.medium)
                        .background(Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                        .accessibilityIdentifier("retention.offerSheet.summary")
                }
                Text("Up to \(RetentionLimits.offersPerSubscription) retention offers per subscription. They appear in transactions as offer type 5, so you can see how many people stayed.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.xLarge)
            Divider()
            footer
        }
        .frame(width: 600)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("retention.offerSheet")
    }

    private var rows: some View {
        VStack(spacing: 0) {
            row(String(localized: "Name")) {
                TextField("Name", text: $draft.name, prompt: Text(verbatim: subscription.map(draft.referenceName(for:)) ?? ""))
                    .textFieldStyle(.roundedBorder)
                    .labelsHidden()
                    .frame(width: 260)
                    .accessibilityIdentifier("retention.offerSheet.name")
                Text("Only you see it")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            Divider()
            row(String(localized: "Subscription")) {
                RetentionSegmentedControl(
                    label: String(localized: "Subscription"),
                    segments: subscriptions.map { RetentionSegment(value: $0.id, title: $0.shortName, identifier: "retention.offerSheet.subscription.\($0.id)") },
                    selection: $draft.subscriptionID
                )
            }
            Divider()
            row(String(localized: "Type")) {
                RetentionSegmentedControl(
                    label: String(localized: "Type"),
                    segments: RetentionOfferMode.allCases.map { RetentionSegment(value: $0, title: $0.title, identifier: "retention.offerSheet.type.\($0.rawValue)") },
                    selection: $draft.mode
                )
            }
            Divider()
            row(String(localized: "Duration")) {
                RetentionSegmentedControl(
                    label: String(localized: "Duration"),
                    segments: RetentionOfferDraft.monthChoices(for: subscription?.period).map {
                        RetentionSegment(value: $0, title: RetentionOfferDuration.monthsTitle($0), identifier: "retention.offerSheet.months.\($0)")
                    },
                    selection: $draft.months
                )
            }
            if draft.mode.hasPrice {
                Divider()
                row(String(localized: "Price in the U.S.")) {
                    TextField("Price", text: $draft.priceText, prompt: Text(verbatim: "2.49"))
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .accessibilityIdentifier("retention.offerSheet.price")
                    Text(subscription.map(draft.priceNote(for:)) ?? "")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
            }
        }
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                .strokeBorder(Palette.separator, lineWidth: 0.5)
        }
    }

    private func row(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: Spacing.small) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }

    private var footer: some View {
        let problem = problems(draft).first
        return HStack(spacing: Spacing.small) {
            if let problem {
                Text(problem.message)
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("retention.offerSheet.problem")
            }
            Spacer()
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)
            Button("Add Offer") { onAdd(draft) }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(problem != nil)
                .accessibilityIdentifier("retention.offerSheet.add")
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }
}
