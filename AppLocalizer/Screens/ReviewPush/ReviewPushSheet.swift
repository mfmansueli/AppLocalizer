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
    /// Images waiting on that confirmation: all of them, or the checked.
    @State private var imagesToConfirm: Bool?
    @State private var isConfirmingDiscard = false

    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ReviewPushViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let run = viewModel.screenshots.run {
                ScreenshotPushProgressView(push: viewModel.push, run: run, onViewResults: viewResults, onDone: finish)
            } else if viewModel.push.phase == .idle {
                review
            } else {
                PushProgressView(push: viewModel.push, onViewResults: viewResults, onDone: finish)
            }
        }
        // Screenshots need the room for old → new side by side.
        .frame(width: showsImages ? 860 : 800, height: showsImages ? 690 : 660)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.sheet")
        .confirmationDialog(
            "Push \(pushToConfirm?.count ?? 0) changes?",
            isPresented: Binding(get: { pushToConfirm != nil }, set: { if !$0 { pushToConfirm = nil } }),
            presenting: pushToConfirm
        ) { changes in
            Button("Push") {
                if let selectedOnly = imagesToConfirm { viewModel.startImagePush(selectedOnly: selectedOnly) }
                viewModel.startPush(changes)
            }
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

    private var showsImages: Bool {
        viewModel.screenshots.run != nil || viewModel.showsScreenshots
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReviewHeader(viewModel: viewModel)
            Divider()
            if viewModel.visibleChanges.isEmpty, !ScreenshotReviewContent.hasContent(viewModel) {
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
                        ScreenshotReviewContent(viewModel: viewModel, onShowInCaptions: showInCaptions)
                    }
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.medium)
                }
            }
            Divider()
            if viewModel.visibleImages.isEmpty {
                ReviewFooter(
                    viewModel: viewModel,
                    onDiscardAll: discardAll,
                    onCancel: { dismiss() },
                    onPush: push
                )
            } else {
                ScreenshotReviewFooter(
                    viewModel: viewModel,
                    onDiscardAll: discardAll,
                    onCancel: { dismiss() },
                    onPushSelected: { push(viewModel.selectedPushableChanges, imagesSelectedOnly: true) },
                    onPushAll: { push(viewModel.pushableChanges, imagesSelectedOnly: false) }
                )
            }
        }
        .modifier(ScreenshotReviewLoader(viewModel: viewModel))
    }

    private func push(_ changes: [PendingChange]) {
        guard !changes.isEmpty else { return }
        if viewModel.confirmationMessage(for: changes) != nil {
            imagesToConfirm = nil
            pushToConfirm = changes
        } else {
            viewModel.startPush(changes)
        }
    }

    /// Pushes text changes and images together; the images wait for a
    /// confirmation the changes need.
    private func push(_ changes: [PendingChange], imagesSelectedOnly: Bool) {
        guard !changes.isEmpty, viewModel.confirmationMessage(for: changes) != nil else {
            viewModel.startImagePush(selectedOnly: imagesSelectedOnly)
            if !changes.isEmpty { viewModel.startPush(changes) }
            return
        }
        imagesToConfirm = imagesSelectedOnly
        pushToConfirm = changes
    }

    /// Opens Captions on the first failing render.
    private func showInCaptions(_ exclusion: ScreenshotPlanExclusion) {
        viewModel.screenshots.showInCaptions(exclusion)
        dismiss()
        navigator.open(.storePage)
    }

    private func discardAll() {
        viewModel.discardVisibleImages()
        guard !viewModel.visibleChanges.isEmpty else { return }
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
        viewModel.screenshots.dismissFinished()
        dismiss()
        navigator.open(.subscriptionPricing, intent: .showResults)
    }

    private func finish() {
        viewModel.push.dismissFinished()
        viewModel.screenshots.dismissFinished()
        dismiss()
    }
}
