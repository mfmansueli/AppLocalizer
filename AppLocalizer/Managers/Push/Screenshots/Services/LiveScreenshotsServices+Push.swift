//
//  LiveScreenshotsServices+Push.swift
//  AppLocalizer
//

import Foundation

extension LiveScreenshotsServices: ScreenshotPushProviding {
    var pushing: any ScreenshotPushServices {
        LiveScreenshotPushServices(client: client)
    }
}
