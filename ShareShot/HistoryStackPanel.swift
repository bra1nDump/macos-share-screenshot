//
//  HistoryStackPanel.swift
//  ShareShot
//
//  Created by Oleg Yakushin on 4/15/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftUI

class HistoryStackPanel: NSPanel {
    init(stackModelState: StackModel) {
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 300, height: 950)
        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = 950
        let panelOriginX = (screenSize.width - panelWidth) / 2 // Center horizontally
        let panelOriginY = screenSize.height - panelHeight // Align with the top of the screen
        let previewRect = NSRect(x: panelOriginX, y: panelOriginY, width: panelWidth, height: panelHeight)
        super.init(contentRect: previewRect, styleMask: [.borderless, .fullSizeContentView], backing: .buffered, defer: false)
        self.backgroundColor = NSColor.clear
        self.isFloatingPanel = true
        self.worksWhenModal = true
        self.isOpaque = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hidesOnDeactivate = false
        let hostingView = NSHostingView(rootView: HistoryStackView(model: stackModelState))
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

