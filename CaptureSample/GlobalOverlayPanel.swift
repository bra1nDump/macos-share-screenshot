//
//  GlobalOverlayWindow.swift
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/16/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import Cocoa

// This class took me 2 days to get somewhat right - the flags are obviously very important.
//
// It accomplishes the following behavior:
// - From anywhere I will be able to use a keyboard shortcut to create a overlay over my entire screen
// - It will block interactions with existing applications while the user is selecting the range to screenshot
// - We will use this overly to draw the cursor and the selection rectangle (delegated to the
//
// The tricky parts:
// - We want the application not to take focus, so everything else on screen remains exacly the same
// - It allows to get keyboard events
//
// Most of this was eye balled and copied from pixel picker / Maccy projects
class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        get { return true }
    }
      override var canBecomeMain: Bool {
          return true
      }
    
    var onComplete: ((Data?) -> Void)?
    
    // Initializer for OverlayPanel
    init(contentRect: NSRect) {
        // Style mask passed here is key! Changing it later will not have the same effect!
        super.init(contentRect: contentRect, styleMask: .nonactivatingPanel, backing: .buffered, defer: true)

        // Not quite sure what it does, sounds like it makes this float over other models
        self.isFloatingPanel = true
        
        // How does the window behave across collections (I assume this means ctrl + up, spaces managment)
        // We might need to further update the styleMask above to get the right combination, but good enough for now
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .fullScreenAuxiliary]

        // Special behavior for models
        self.worksWhenModal = true

        // Track the mouse
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false
        self.backgroundColor = .clear
        
        let nsHostingContentView = NSHostingView(rootView: CaptureOverlayView(
            initialMousePosition: convertToSwiftUICoordinates(NSEvent.mouseLocation, in: self),
            onComplete: { imageData in
                // If image data is nil - still call on complete for proper cleanup of the panel
                self.onComplete?(imageData)
                
                            self.contentView = nil
                            self.close()
                           
                           cShowCursor()
                       }
        ))
        self.contentView = nsHostingContentView
        
        // Additional window setup
        makeKeyAndOrderFront(self)

        cHideCursor()
    }
}

