//
//  AppDelegate.swift
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/16/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        
    }

    func showOverlayWindow() {
        var screenRect = NSScreen.main?.frame ?? NSRect.zero
            
        // For debugging only allocate part of the screen for testing to be able to stop debugging
        screenRect = screenRect.insetBy(dx: screenRect.width / 4, dy: screenRect.height / 4)
        
        let overlayWindow = OverlayWindow(contentRect: screenRect, styleMask: .borderless, backing: .buffered, defer: false)
        
        overlayWindow.makeKeyAndOrderFront(nil)
        
        // Note: We might need this?
//        NSApp.activate(ignoringOtherApps: true)
    }

    // NOOP - we handle this from within the window itself
//    func hideOverlayWindow() {
//        overlayWindow.orderOut(nil)
//    }
}
