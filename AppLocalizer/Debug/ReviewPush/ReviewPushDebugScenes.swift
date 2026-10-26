//
//  ReviewPushDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Review & Push and Activity DEBUG scenes (`-AppLocalizerDebugScene <id>`),
/// as the design's "Review & Push" board shows them.
enum ReviewPushDebugScenes {
    static let ids = [
        "review", "review-empty", "review-assistant", "push-progress", "push-partial", "push-conflict",
        "activity", "banner-offline", "banner-rate", "banner-api",
    ]

    @MainActor
    static func view(for id: String) -> AnyView? {
        reviewScene(id) ?? bannerScene(id)
    }

    @MainActor
    private static func reviewScene(_ id: String) -> AnyView? {
        switch id {
        case "review":
            scene(DebugReviewData.reviewChanges, sheet: .review)
        case "review-empty":
            scene([], sheet: .review)
        case "review-assistant":
            scene(DebugReviewData.assistantChanges, sheet: .review)
        case "push-progress":
            scene(DebugReviewData.annualPriceChanges, sheet: .review, transport: DebugPushTransport(delay: .milliseconds(900)), autoPush: true)
        case "push-partial":
            scene(
                DebugReviewData.annualPriceChanges,
                sheet: .review,
                transport: DebugPushTransport(delay: .milliseconds(20), failures: DebugReviewData.partialFailures),
                autoPush: true
            )
        case "push-conflict":
            scene(DebugReviewData.conflictChanges, sheet: .review)
        case "activity":
            scene([], sheet: .activity)
        default:
            nil
        }
    }

    @MainActor
    private static func bannerScene(_ id: String) -> AnyView? {
        switch id {
        case "banner-offline":
            scene(DebugReviewData.annualPriceChanges, notice: .offline)
        case "banner-rate":
            scene(DebugReviewData.annualPriceChanges, notice: .rateLimited(resumeAt: noon))
        case "banner-api":
            scene(
                DebugReviewData.annualPriceChanges,
                notice: .apiError(AppStoreConnectError.rejected(
                    statusCode: 409,
                    code: "ENTITY_ERROR.ATTRIBUTE.INVALID",
                    detail: "An attribute value is not acceptable for the current resource."
                ).pushFailureText)
            )
        default:
            nil
        }
    }

    private static var noon: Date {
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now) ?? .now
    }

    @MainActor
    private static func scene(
        _ changes: [PendingChange],
        sheet: WorkspaceSheet? = nil,
        transport: DebugPushTransport = DebugPushTransport(),
        autoPush: Bool = false,
        notice: PushNotice? = nil
    ) -> AnyView {
        var services = WorkspaceServices.debug
        services.push = transport
        return AnyView(DebugMainScene(
            services: services,
            pendingChanges: changes,
            pushRecords: DebugReviewData.activityRecords,
            presentedSheet: sheet,
            autoPush: autoPush,
            notice: notice
        ))
    }
}
#endif
