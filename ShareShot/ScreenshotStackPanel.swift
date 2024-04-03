//
//  ScreenshotStackPanel.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/6/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import Cocoa

class ScreenshotStackPanel: NSPanel {
    init(imageData: [ImageData]) {
        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = 950
        let previewRect = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        
        super.init(contentRect: previewRect, styleMask: .borderless, backing: .buffered, defer: false)
        self.backgroundColor = NSColor.clear
        self.isFloatingPanel = true
        self.worksWhenModal = true
        self.isOpaque = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hidesOnDeactivate = false
        
        let hostingView = NSHostingView(rootView: CaptureStackView(capturedImages: imageData))
        hostingView.frame = previewRect
        
        if let contentView = self.contentView {
            contentView.addSubview(hostingView)
        } else {
            print("Warning: contentView is nil.")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

