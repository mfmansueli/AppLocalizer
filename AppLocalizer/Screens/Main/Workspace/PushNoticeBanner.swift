//
//  PushNoticeBanner.swift
//  AppLocalizer
//

import SwiftUI

/// The workspace banner after a push stopped or partly failed: offline,
/// rate limited, an API error with Apple's text, or "2 of 26 failed" with
/// Review Failed.
struct PushNoticeBanner: View {
    let notice: PushNotice
    let push: PushController
    let onReviewFailed: () -> Void

    var body: some View {
        Banner(kind: notice.kind, title: notice.title, message: notice.message) {
            if case .partialFailure = notice {
                Button("Review Failed", action: onReviewFailed)
                    .accessibilityIdentifier("banner.reviewFailed")
            }
            Button {
                push.dismissNotice()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Dismiss"))
        }
        .accessibilityIdentifier("workspace.banner")
    }
}
