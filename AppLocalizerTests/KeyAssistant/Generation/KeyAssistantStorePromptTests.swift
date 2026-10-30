//
//  KeyAssistantStorePromptTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What Generate Suggestions… sends for a Store Page, on the fixture
/// listing: each part's title and size, the prompt, and the total.
@Suite("KeyAssistantStorePrompt")
struct KeyAssistantStorePromptTests {
    private let listing = StorePageFixtures.listing()
    private let folder = ProjectFolderExcerpt(
        tag: "v1.3",
        commits: ["Add weekly reflections", "Mood tags"],
        changelog: ChangelogSection(markdown: "## 1.4\n- Weekly reflections.", version: "2.0")
    )

    @Test func onlyStoreTextWithoutTheFolderOrReviews() {
        let plan = KeyAssistantStorePrompt.plan(listing: listing, context: .init())
        #expect(plan.items.map(\.id) == ["store"])
        #expect(plan.items.first?.title == "Store Page text · English (U.S.), German")
        #expect(plan.title == "Store Page · English (U.S.), German")
        #expect(plan.user.contains("## en-US · English (U.S.) (primary language)"))
        #expect(plan.user.contains(#"subtitle (max 30 characters): "Private notes, gentle prompts""#))
        #expect(plan.user.contains("keywords (max 100 bytes)"))
        #expect(plan.user.contains("whatsNew (max 4000 characters): (empty)"))
        #expect(!plan.user.contains("description"))
        #expect(plan.system.contains(#"{"suggestions": []}"#))
    }

    @Test func theFolderAndReviewsAreTheirOwnParts() throws {
        let reviews = [CustomerReview(rating: 5, title: "Calm", body: "Every night.\nLove it.")]
        let plan = KeyAssistantStorePrompt.plan(listing: listing, context: .init(folder: folder, folderPath: "~/Developer/Lumen", reviews: reviews))
        #expect(plan.items.map(\.title) == [
            "Store Page text · English (U.S.), German",
            "2 commit messages since v1.3 · ~/Developer/Lumen",
            "CHANGELOG.md · the 1.4 section",
            "Last 1 App Store reviews",
        ])
        #expect(plan.user.contains("## Commit messages since v1.3\n- Add weekly reflections\n- Mood tags"))
        #expect(plan.user.contains("★★★★★ Calm: Every night. Love it."))
        let commits = try #require(plan.items.first { $0.id == "commits" })
        #expect(commits.tokens == KeyAssistantTokens.estimate("## Commit messages since v1.3\n- Add weekly reflections\n- Mood tags"))
        #expect(plan.totalTokens == KeyAssistantTokens.estimate(plan.system) + KeyAssistantTokens.estimate(plan.user))
    }

    @Test func aFolderThatCantBeReadIsANote() {
        let missing = ProjectFolderExcerpt(problem: "The project folder can’t be found.")
        let plan = KeyAssistantStorePrompt.plan(listing: listing, context: .init(folder: missing, folderPath: "~/Gone"))
        #expect(plan.notes == ["The project folder can’t be found."])
        #expect(plan.items.count == 1)
    }

    @Test func tokensAreAQuarterOfTheCharacters() {
        #expect(KeyAssistantTokens.estimate("abcde") == 2)
        #expect(KeyAssistantTokens.formatted(400) == 400.formatted())
        #expect(KeyAssistantTokens.formatted(9400) == 9.4.formatted(.number.precision(.fractionLength(1))) + "k")
        let plan = KeyAssistantStorePrompt.plan(listing: listing, context: .init())
        #expect(plan.totalText(vendor: .anthropic).hasSuffix("tokens in, billed to your Anthropic account. Source code isn’t sent."))
    }
}
