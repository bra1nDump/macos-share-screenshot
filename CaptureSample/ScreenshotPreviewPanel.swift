//
//  ScreenshotPreviewPanel.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/6/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

class ScreenshotPreviewPanel: NSPanel {
    init(imageData: [ImageData]) {
        let previewRect = NSRect(x: 0, y: 0, width: 300, height: 950)
        super.init(contentRect: previewRect, styleMask: .borderless, backing: .buffered, defer: false)
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.level = .floating
        let hostingView = NSHostingView(rootView: CaptureStackView(capturedImages: imageData))
        hostingView.frame = previewRect
        self.contentView?.addSubview(hostingView)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
