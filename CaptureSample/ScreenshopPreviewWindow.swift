//
//  ScreenshopPreviewWindow.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/16/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import Cocoa

class ScreenshotPreview: NSWindow {
    init(imageData: [ImageData]) {
        let windowRect = NSRect(x: 0, y: 0, width: 300, height: 950)
        super.init(contentRect: windowRect, styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        
        self.isReleasedWhenClosed = false
        self.center()
        self.title = "Screenshot Preview"
        self.contentView = NSHostingView(rootView: CaptureStackView(capturedImages: imageData))
        self.contentView?.frame = windowRect
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AlwaysOnTopWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.level = .floating
        
        let screenshotPreviewWindow = ScreenshotPreviewWindow(imageData: /* ImageData */)
        screenshotPreviewWindow.makeKeyAndOrderFront(nil)
    }
}
