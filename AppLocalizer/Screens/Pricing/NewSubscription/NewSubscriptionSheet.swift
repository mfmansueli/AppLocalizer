//
//  NewSubscriptionSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Create Subscription: the group (one the app has, or a new one), the
/// subscription's reference name, product ID and duration, its display
/// name and description in the app's primary language, and its starting
/// price in the United States. Add to Review & Push queues it; the push
/// creates it. Names and the product ID follow the group and duration
/// until the person edits them. Add with a problem scrolls to the first
/// field that has one and puts the cursor there.
struct NewSubscriptionSheet: View {
    let appName: String
    let bundleID: String
    let groups: [PricingProductGroup]
    let problems: (NewSubscription) -> [NewSubscriptionProblem]
    let onCancel: () -> Void
    let onAdd: (NewSubscription) -> Void

    @State private var draft: NewSubscription
    @State private var groupChoice: String
    @State private var newGroupReferenceName: String
    @State private var newGroupDisplayName: String
    @State private var priceText = ""
    @State private var edited: Set<NewSubscriptionField> = []
    @State private var showsMissing = false
    /// The field Add scrolls to: the first with a problem.
    @State private var scrollTarget: NewSubscriptionField?
    @FocusState private var focusedField: NewSubscriptionField?

    private static let newGroupTag = "new"

    init(
        appName: String,
        bundleID: String,
        groups: [PricingProductGroup],
        initial: NewSubscription,
        problems: @escaping (NewSubscription) -> [NewSubscriptionProblem],
        onCancel: @escaping () -> Void,
        onAdd: @escaping (NewSubscription) -> Void
    ) {
        self.appName = appName
        self.bundleID = bundleID
        self.groups = groups
        self.problems = problems
        self.onCancel = onCancel
        self.onAdd = onAdd
        _draft = State(initialValue: initial)
        switch initial.group {
        case let .existing(id, _):
            _groupChoice = State(initialValue: id)
            let name = String(localized: "\(NewSubscription.shortName(of: appName)) Premium")
            _newGroupReferenceName = State(initialValue: name)
            _newGroupDisplayName = State(initialValue: name)
        case let .new(referenceName, displayName):
            _groupChoice = State(initialValue: Self.newGroupTag)
            _newGroupReferenceName = State(initialValue: referenceName)
            _newGroupDisplayName = State(initialValue: displayName)
        }
        _priceText = State(initialValue: initial.price.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
    }

    /// The form as a new subscription.
    private var subscription: NewSubscription {
        var subscription = draft
        subscription.group = if groupChoice == Self.newGroupTag {
            .new(referenceName: newGroupReferenceName, displayName: newGroupDisplayName)
        } else {
            .existing(id: groupChoice, referenceName: groups.first { $0.id == groupChoice }?.name ?? groupChoice)
        }
        subscription.price = NewSubscription.price(from: priceText)
        return subscription
    }

    private var currentProblems: [NewSubscriptionProblem] {
        var problems = problems(subscription)
        if !priceText.trimmingCharacters(in: .whitespaces).isEmpty, subscription.price == nil {
            problems.removeAll { $0 == .missing(.price) }
            problems.append(.invalidPrice)
        }
        return problems
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollViewReader { proxy in
                Form {
                    groupSection
                    subscriptionSection
                    storeSection
                    priceSection
                    reviewSection
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .onChange(of: scrollTarget) {
                    guard let scrollTarget else { return }
                    withAnimation { proxy.scrollTo(scrollTarget, anchor: .center) }
                    focusedField = scrollTarget
                    self.scrollTarget = nil
                }
            }
            Divider()
            footer
        }
        .frame(width: 560)
        .frame(minHeight: 420, idealHeight: 640, maxHeight: 700)
        .onChange(of: draft.period) { updateSuggestions() }
        .onChange(of: groupChoice) { updateSuggestions() }
        .onChange(of: newGroupReferenceName) { updateSuggestions() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.newSubscription")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text("New subscription")
                .font(.title2.weight(.semibold))
            Text("For \(appName). It waits in Review & Push; nothing is created in App Store Connect until you push.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.top, Spacing.xLarge)
    }

    // MARK: - Sections

    private var groupSection: some View {
        Section {
            Picker("Group", selection: $groupChoice) {
                ForEach(groups) { group in
                    Text(group.name).tag(group.id)
                }
                if !groups.isEmpty { Divider() }
                Text("New Group").tag(Self.newGroupTag)
            }
            .accessibilityIdentifier("pricing.newSubscription.group")
            if groupChoice == Self.newGroupTag {
                field(.groupReferenceName, text: $newGroupReferenceName)
                field(.groupDisplayName, text: $newGroupDisplayName, prompt: String(localized: "Shown on the App Store"))
            }
        } header: {
            Text("Group")
        } footer: {
            note("Customers have one subscription of a group at a time and can move between them, like Monthly and Annual.")
        }
    }

    private var subscriptionSection: some View {
        Section {
            field(.referenceName, text: tracked(\.referenceName, as: .referenceName))
            field(.productID, text: tracked(\.productID, as: .productID), monospaced: true)
            Picker("Duration", selection: $draft.period) {
                ForEach(SubscriptionPeriod.allCases, id: \.self) { period in
                    Text(period.title).tag(period)
                }
            }
            .accessibilityIdentifier("pricing.newSubscription.period")
            Toggle("Family Sharing", isOn: $draft.isFamilySharable)
                .accessibilityIdentifier("pricing.newSubscription.familySharing")
        } header: {
            Text("Subscription")
        } footer: {
            note("The product ID is what \(appName)’s code buys. It can’t be changed or used again. Family Sharing can’t be turned off once it’s on.")
        }
    }

    private var storeSection: some View {
        Section {
            field(.displayName, text: tracked(\.displayName, as: .displayName))
            field(.description, text: $draft.description, prompt: String(localized: "What subscribers get"), isMultiline: true)
        } header: {
            Text("On the App Store · \(draft.locale.name)")
        } footer: {
            note("Shown on the purchase sheet and in Settings → Subscriptions. Add other languages in Store Page → In-App Texts after the push.")
        }
    }

    private var priceSection: some View {
        Section {
            LabeledContent {
                HStack(spacing: Spacing.xSmall) {
                    TextField("Price", text: $priceText, prompt: Text(verbatim: "9.99"))
                        .labelsHidden()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110)
                        .focused($focusedField, equals: .price)
                        .accessibilityIdentifier("pricing.newSubscription.price")
                    Text(verbatim: "USD")
                        .foregroundStyle(Palette.label2)
                }
            } label: {
                Text("Price in the United States")
            }
            .id(NewSubscriptionField.price)
            problemText(for: .price)
        } header: {
            Text("Starting price")
        } footer: {
            note("""
            Every other country or region gets Apple’s equalized price, and the subscription is available \
            everywhere. Change the prices in Pricing after the push.
            """)
        }
    }

    private var reviewSection: some View {
        Section {
            field(.reviewNote, text: $draft.reviewNote, prompt: String(localized: "Optional: how App Review finds the paywall"), isMultiline: true)
        } header: {
            Text("App Review")
        }
    }

    private var footer: some View {
        HStack(spacing: Spacing.small) {
            Text("Add its review screenshot in App Store Connect before you submit it.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("pricing.newSubscription.cancel")
            Button("Add to Review & Push", action: add)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("pricing.newSubscription.add")
        }
        .buttonBorderShape(.capsule)
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }

    // MARK: - Fields

    private func field(
        _ field: NewSubscriptionField,
        text: Binding<String>,
        prompt: String? = nil,
        monospaced: Bool = false,
        isMultiline: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Group {
                    if isMultiline {
                        TextField(field.title, text: text, prompt: prompt.map { Text($0) }, axis: .vertical)
                            .lineLimit(2...5)
                    } else {
                        TextField(field.title, text: text, prompt: prompt.map { Text($0) })
                    }
                }
                .font(monospaced ? .body.monospaced() : .body)
                .focused($focusedField, equals: field)
                .accessibilityIdentifier("pricing.newSubscription.\(field.rawValue)")
                if let limit = field.limit, limit <= 100 {
                    let count = NewSubscription.trimmed(text.wrappedValue).count
                    Text(verbatim: "\(count)/\(limit)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(count > limit ? Palette.danger : Palette.label3)
                }
            }
            problemText(for: field)
        }
        .id(field)
    }

    @ViewBuilder
    private func problemText(for field: NewSubscriptionField) -> some View {
        if let problem = currentProblems.first(where: { $0.field == field && (showsMissing || !Self.isMissing($0)) }) {
            Text(problem.message)
                .font(.caption)
                .foregroundStyle(Palette.danger)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("pricing.newSubscription.\(field.rawValue).problem")
        }
    }

    private func note(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Palette.label2)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// A binding that marks the field as the person's once they type in it.
    private func tracked(_ keyPath: WritableKeyPath<NewSubscription, String>, as field: NewSubscriptionField) -> Binding<String> {
        Binding {
            draft[keyPath: keyPath]
        } set: { value in
            if value != draft[keyPath: keyPath] { edited.insert(field) }
            draft[keyPath: keyPath] = value
        }
    }

    private static func isMissing(_ problem: NewSubscriptionProblem) -> Bool {
        if case .missing = problem { return true }
        return false
    }

    /// Names and the product ID follow the group and duration until edited.
    private func updateSuggestions() {
        let groupName = subscription.group.referenceName
        let name = "\(groupName) \(draft.period.shortTitle)"
        if !edited.contains(.referenceName) { draft.referenceName = name }
        if !edited.contains(.displayName) { draft.displayName = name }
        if !edited.contains(.productID) { draft.productID = PricingViewModel.suggestedProductID(bundleID: bundleID, period: draft.period) }
    }

    private func add() {
        guard let first = currentProblems.first else {
            onAdd(subscription)
            return
        }
        showsMissing = true
        scrollTarget = first.field
    }
}
