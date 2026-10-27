//
//  ScreenshotReviewSection.swift
//  AppLocalizer
//

import SwiftUI

/// One app's screenshots in review: "LUMEN JOURNAL · SCREENSHOTS · VERSION
/// 1.4", why nothing can go when the version is live, and a group per set.
struct ScreenshotReviewSection: View {
    let plan: ScreenshotPushPlan
    let viewModel: ReviewPushViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(plan.heading.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.label2)
                .padding(.top, Spacing.xxSmall)
                .padding(.horizontal, Spacing.small)
                .accessibilityAddTraits(.isHeader)
            if let reason = plan.blockedReason {
                Banner(kind: .warning, title: String(localized: "These images can’t be pushed yet."), message: reason)
                    .padding(.horizontal, -Spacing.large)
                    .accessibilityIdentifier("review.shots.blocked")
            }
            ForEach(plan.groups) { group in
                ScreenshotReviewGroupView(group: group, viewModel: viewModel, primaryLocaleName: plan.primaryLocaleName)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.shots.section.\(plan.appID)")
    }
}
