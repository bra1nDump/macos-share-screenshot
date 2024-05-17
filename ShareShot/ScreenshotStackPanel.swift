//
//  ScreenshotStackPanel.swift
//  CaptureSample
//
//  Created by Oleg Yakushin on 1/6/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

class ScreenshotStackPanel: NSPanel {
    init(stackModelState: StackModel) {
        // Get the screen size, safely handling the optional value
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let panelWidth = min(300, screenFrame.width * 0.8)
        let panelHeight = min(950, screenFrame.height * 0.95)
        let previewRect = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        
        // Initialize the panel with the specified parameters
        super.init(contentRect: previewRect, styleMask: .borderless, backing: .buffered, defer: false)
        
        // Configure the panel properties
        self.backgroundColor = NSColor.clear
        self.isFloatingPanel = true
        self.worksWhenModal = true
        self.isOpaque = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hidesOnDeactivate = false
        
        // Create an NSHostingView with the root SwiftUI view
        let hostingView = NSHostingView(rootView: CaptureStackView(model: stackModelState))
        hostingView.frame = previewRect
        
        // Add the hostingView to the panel's contentView
        if let contentView = self.contentView {
            contentView.addSubview(hostingView)
        } else {
            // Warning if contentView is nil
            print("Warning: contentView is nil.")
        }
    }
    
    // Required initializer with fatalError, as it is not used
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

