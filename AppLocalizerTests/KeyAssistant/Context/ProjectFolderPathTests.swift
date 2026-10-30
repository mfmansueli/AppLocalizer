//
//  ProjectFolderPathTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// Project folders as people read them, with `~` for the home folder.
@Suite("ProjectFolderPath")
struct ProjectFolderPathTests {
    @Test func abbreviatesAndExpandsTheHomeFolder() {
        #expect(ProjectFolderPath.abbreviated("/Users/me/Developer/Lumen", home: "/Users/me") == "~/Developer/Lumen")
        #expect(ProjectFolderPath.abbreviated("/Users/meg/Lumen", home: "/Users/me") == "/Users/meg/Lumen")
        #expect(ProjectFolderPath.expanded("~/Developer/Lumen", home: "/Users/me") == "/Users/me/Developer/Lumen")
        #expect(ProjectFolderPath.expanded("/Volumes/Work", home: "/Users/me") == "/Volumes/Work")
    }

    @Test func theHomeIsThePersonsNotTheContainers() {
        #expect(!ProjectFolderPath.home.contains("/Library/Containers/"))
    }
}
