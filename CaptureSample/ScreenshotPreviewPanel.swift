//
//  ScreenshotPreviewPanel.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/6/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

class ScreenshotPreviewPanel: NSPanel {
    override var canBecomeKey: Bool {
            return true
        }
    init(imageData: [ImageData]) {
        let previewRect = NSRect(x: -20, y: 0, width: 300, height: 950)
        super.init(contentRect: previewRect, styleMask: .borderless, backing: .buffered, defer: false)
        self.backgroundColor = NSColor.clear
        self.isFloatingPanel = true
        self.worksWhenModal = true
        self.isOpaque = false
        self.level = .mainMenu
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let hostingView = NSHostingView(rootView: CaptureStackView(capturedImages: imageData))
        hostingView.frame = previewRect
        self.contentView?.addSubview(hostingView)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
