//
//  MCPToolbox.swift
//  AppLocalizer
//

import Foundation

/// The tools the server offers. A section's tools join `standard` once the
/// section can read and validate what they need.
@MainActor
struct MCPToolbox {
    let tools: [any MCPTool]

    static var standard: MCPToolbox {
        MCPToolbox(tools: [
            ListAppsTool(),
            GetListingTool(),
            ListMissingTranslationsTool(),
            ProposeListingTextTool(),
            GetInAppTextsTool(),
            ProposeInAppTextsTool(),
            GetPricesTool(),
            GetPricePointsTool(),
            ProposePricesTool(),
            GetSubscriptionsTool(),
            ProposeSubscriptionTool(),
            GetRetentionTool(),
            ProposeRetentionMessageTool(),
            ProposeRetentionOfferTool(),
            GetPrivacyQuestionnaireTool(),
            ProposePrivacyAnswersTool(),
            GetAgeRatingTool(),
            ProposeAgeRatingTool(),
            GetScreenshotContextTool(),
            ListCapturesTool(),
            GetCaptureTool(),
            GetTemplateTool(),
            GetCaptionsTool(),
            MeasureCaptionTool(),
            RenderPreviewTool(),
            ProposeTemplateTool(),
            ProposeCaptionsTool(),
            ListProposalsTool(),
            GetStorePageTool(),
            GetAppInformationTool(),
            SuggestFieldsTool(),
            BeginSuggestionsTool(),
            EndSuggestionsTool(),
            GetCapturePlanTool(),
            UpdateCapturePlanTool(),
            ProposeScreensTool(),
            ReportCaptureTool(),
            ReportCaptureProblemTool(),
            ReportRecordingTool(),
            ListRecordingMomentsTool(),
            RerecordMomentTool(),
            ProposeArtworkVariantTool(),
            StartDisplayRecordingTool(),
            FinishDisplayRecordingTool(),
            NextStepTool(),
            GetDesignBriefTool(),
            RenderArtworkTool(),
            ProposeDirectionTool(),
            ReviseDirectionTool(),
            ProposeArtworkConceptTool(),
            ReviseArtworkConceptTool(),
            ReviseAppPreviewTool(),
            SetAppPreviewMusicTool(),
            ReportDesignSourceTool(),
            ReportAppSupportTool(),
            AnswerAppQuestionsTool(),
        ])
    }

    func tool(named name: String) -> (any MCPTool)? {
        tools.first { $0.definition.name == name }
    }

    var toolNames: Set<String> {
        Set(tools.map(\.definition.name))
    }

    /// The `tools/list` result.
    var listResult: JSONValue {
        ["tools": .array(tools.map(\.definition.json))]
    }
}
