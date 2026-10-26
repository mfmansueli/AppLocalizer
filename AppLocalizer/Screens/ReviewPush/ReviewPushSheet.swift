//
//  ReviewPushSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Review & Push (⇧⌘P, 800 pt): every pending change grouped by app and
/// section, each as old → new with its source, a checkbox and a discard
/// button. Once a push starts, the same sheet shows its progress.
struct ReviewPushSheet: View {
    @State private var viewModel: ReviewPushViewModel
    @State private var pushToConfirm: [PendingChange]?
    @State private var isConfirmingDiscard = false

    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ReviewPushViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.push.phase == .idle {
                review
            } else {
                PushProgressView(push: viewModel.push, onViewResults: viewResults, onDone: finish)
            }
        }
        .frame(width: 800, height: 660)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.sheet")
        .confirmationDialog(
            "Push \(pushToConfirm?.count ?? 0) changes?",
            isPresented: Binding(get: { pushToConfirm != nil }, set: { if !$0 { pushToConfirm = nil } }),
            presenting: pushToConfirm
        ) { changes in
            Button("Push") { viewModel.startPush(changes) }
                .accessibilityIdentifier("review.confirmPush")
            Button("Cancel", role: .cancel) {}
        } message: { changes in
            Text(viewModel.confirmationMessage(for: changes) ?? "")
        }
        .confirmationDialog(
            "Discard \(viewModel.visibleChanges.count) changes?",
            isPresented: $isConfirmingDiscard
        ) {
            Button("Discard All", role: .destructive) { viewModel.discardVisible() }
                .accessibilityIdentifier("review.confirmDiscard")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They're removed from this Mac. Nothing in App Store Connect changes.")
        }
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReviewHeader(viewModel: viewModel)
            Divider()
            if viewModel.visibleChanges.isEmpty {
                ContentUnavailableView(
                    "Nothing to push",
                    systemImage: "checkmark.circle",
                    description: Text("Edits in Pricing, Store Page and App Information collect here until you push them.")
                )
                .frame(maxHeight: .infinity)
                .accessibilityIdentifier("review.empty")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.medium) {
                        ForEach(viewModel.appGroups) { app in
                            Text(app.appName)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(Palette.label2)
                                .padding(.top, Spacing.xSmall)
                            ForEach(app.groups) { group in
                                ReviewChangeGroupView(
                                    group: group,
                                    viewModel: viewModel,
                                    onEditSchedule: editScheduleAction(for: group)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.medium)
                }
            }
            Divider()
            ReviewFooter(
                viewModel: viewModel,
                onDiscardAll: discardAll,
                onCancel: { dismiss() },
                onPush: push
            )
        }
    }

    private func push(_ changes: [PendingChange]) {
        guard !changes.isEmpty else { return }
        if viewModel.confirmationMessage(for: changes) != nil {
            pushToConfirm = changes
        } else {
            viewModel.startPush(changes)
        }
    }

    private func discardAll() {
        if preferences.confirmsDiscarding {
            isConfirmingDiscard = true
        } else {
            viewModel.discardVisible()
        }
    }

    private func editScheduleAction(for group: ReviewChangeGroup) -> (() -> Void)? {
        guard group.section == .subscriptionPricing, let productID = group.groupID else { return nil }
        return {
            dismiss()
            navigator.open(.subscriptionPricing, intent: .editPriceSchedule(productID: productID))
        }
    }

    private func viewResults() {
        viewModel.push.dismissFinished()
        dismiss()
        navigator.open(.subscriptionPricing, intent: .showResults)
    }

    private func finish() {
        viewModel.push.dismissFinished()
        dismiss()
    }
}
