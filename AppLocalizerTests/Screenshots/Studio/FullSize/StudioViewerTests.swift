//
//  StudioViewerTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The full-size viewer's place among its items: the count it shows, and
/// the arrows that stop at either end.
@Suite("Full-size viewer")
struct StudioViewerTests {
    /// `count` App Previews, as stand-ins for any item.
    private func items(_ count: Int) -> [StudioViewerItem] {
        (0..<count).map { index in
            let file = ExtrasPreviewFile(
                displayType: .iPhone, locale: "en-US", recordedLocale: "en-US", fileID: "file-\(index)", seconds: 24,
                pixelSize: PixelSize(width: 886, height: 1920), byteCount: 1, posterSeconds: 5
            )
            return StudioViewerItem(id: "item.\(index)", title: "Item \(index + 1)", subtitle: "", content: .appPreview(file))
        }
    }

    @Test func nothingToShowIsNoViewer() {
        #expect(StudioViewer(items: []) == nil)
    }

    @Test func itOpensOnTheItemClicked() throws {
        let viewer = try #require(StudioViewer(items: items(5), index: 1))
        #expect(viewer.current.id == "item.1")
        #expect(viewer.countTitle == "2 of 5")
        #expect(viewer.hasPrevious)
        #expect(viewer.hasNext)
    }

    @Test func anIndexOutsideTheItemsOpensTheNearest() throws {
        #expect(try #require(StudioViewer(items: items(3), index: 9)).current.id == "item.2")
        #expect(try #require(StudioViewer(items: items(3), index: -2)).current.id == "item.0")
    }

    @Test func theArrowsStopAtEitherEnd() throws {
        var viewer = try #require(StudioViewer(items: items(3)))
        #expect(!viewer.hasPrevious)
        viewer.step(-1)
        #expect(viewer.index == 0)
        viewer.step(1)
        viewer.step(1)
        #expect(viewer.current.id == "item.2")
        #expect(!viewer.hasNext)
        viewer.step(1)
        #expect(viewer.countTitle == "3 of 3")
    }

    @Test func oneItemHasNoCount() throws {
        let viewer = try #require(StudioViewer(items: items(1)))
        #expect(viewer.countTitle == nil)
        #expect(!viewer.hasPrevious && !viewer.hasNext)
    }

    @Test func eachItemKnowsItsShape() {
        let file = ExtrasPreviewFile(
            displayType: .iPad, locale: "en-US", recordedLocale: "en-US", fileID: "ipad", seconds: 24,
            pixelSize: PixelSize(width: 1200, height: 1600), byteCount: 1, posterSeconds: 5
        )
        let content = StudioViewerContent.appPreview(file)
        #expect(content.isAppPreview)
        #expect(abs(content.aspect - 1600.0 / 1200.0) < 0.000_1)
        #expect(content.pixelSize == PixelSize(width: 1200, height: 1600))
    }
}
