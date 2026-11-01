//
//  ClaudeCodeDeepLinkTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Open in Terminal's link: Claude Code's `claude-cli://open`.
@Suite("Claude Code deep link")
struct ClaudeCodeDeepLinkTests {
    private func query(_ url: URL?) throws -> [String: String] {
        let link = try #require(url)
        let components = try #require(URLComponents(url: link, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "claude-cli")
        #expect(components.host == "open")
        return Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
    }

    @Test func theFolderAndPromptSurviveEncoding() throws {
        let prompt = "Suggest What’s New & keywords for 1+1=2? #fast / done"
        let items = try query(ClaudeCodeDeepLink.url(folder: "/Users/sam/My Apps/Lumen", prompt: prompt))
        #expect(items == ["cwd": "/Users/sam/My Apps/Lumen", "q": prompt])
    }

    @Test func withoutAPromptOnlyTheFolder() throws {
        #expect(try query(ClaudeCodeDeepLink.url(folder: "/Users/sam/Lumen", prompt: nil)) == ["cwd": "/Users/sam/Lumen"])
        #expect(try query(ClaudeCodeDeepLink.url(folder: "/Users/sam/Lumen", prompt: "")) == ["cwd": "/Users/sam/Lumen"])
    }

    @Test func promptsOverTheLimitHaveNoLink() {
        let limit = ClaudeCodeDeepLink.maximumPromptLength
        #expect(ClaudeCodeDeepLink.url(folder: "/x", prompt: String(repeating: "a", count: limit)) != nil)
        #expect(ClaudeCodeDeepLink.url(folder: "/x", prompt: String(repeating: "a", count: limit + 1)) == nil)
    }
}
