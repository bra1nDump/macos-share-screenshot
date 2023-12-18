//
//  GlobalOverlayWindow.swift
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/16/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import Carbon
import Cocoa

// Define your SwiftUI view
struct CaptureOverlayView: View {
    enum CaptureOverlayState {
        case initializing
        
        case placingAnchor(currentVirtualCursorPosition: CGPoint)
        // Starts out the same as anchor
        case selectingFrame(anchorPoint: CGPoint, virtualCursorPosition: CGPoint)
        
        // Final state does not need to be represented here, will be called out with a frame and recored once this window dies
        // hmmm but for gifs this would need to change, so lets just keep it here
        
        case capturing(frame: CGRect)
    }
    
    let onComplete: (_ imageData: Data?) -> Void
    @State private var state: CaptureOverlayState = .initializing
    
    // TODO: Create a class and place state that needs cleaning there - for instance place global monitors there and cleanup after when instance is thrown away
    
    init(onComplete: @escaping (_ imageData: Data?) -> Void) {
        self.onComplete = onComplete
        
        // TODO: Add event to find first down
        
        // Only signup after first mouse down event
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) {
            event in
            print("place anchor")
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) {
            event in
            print("complete selection at current poisition, start capturing")
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) {
            event in
//            print("mouse moved")
            // TODO: Write update to state
        }
    }

    var body: some View {
        // TODO: Parametrize the cursor parameters with constant configurations and make it follow the current virtual cursor, or if in another state - don't show it at all
        // Use GeometryReader to get the size of the view
        GeometryReader { geometry in
            // Your SwiftUI code goes here.
            // You can draw the crosshair or the selection rectangle based on the anchorPoint and currentPoint
            // For example, a simple crosshair can be drawn like this:
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                path.move(to: CGPoint(x: center.x - 10, y: center.y))
                path.addLine(to: CGPoint(x: center.x + 10, y: center.y))
                path.move(to: CGPoint(x: center.x, y: center.y - 10))
                path.addLine(to: CGPoint(x: center.x, y: center.y + 10))
            }
            .stroke(Color.blue, lineWidth: 2)
        }
        .background(Color.blue.opacity(0.2))
    }
}


typealias ImageData = Data

// Copy all functionality in window to OverlayPanel

// This class is in charge of managing the panels which are brought to the front
// (above other apps) without actually activating PixelPicker itself.
class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        get { return true }
    }
    
    override var canBecomeMain: Bool {
        get { return true }
    }
    
    // Initializer for OverlayPanel
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless.union(.fullSizeContentView), backing: backingStoreType, defer: flag)

        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false // Change to true if you don't want to intercept events
        self.level = .screenSaver
        self.backgroundColor = .blue.withAlphaComponent(0.2)

        // Set up window properties
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.level = .popUpMenu
        self.styleMask = .nonactivatingPanel
        self.isOpaque = false
        self.acceptsMouseMovedEvents = true

        // Additional setup transferred from awakeFromNib
        // ...

        // Setup content view with CaptureOverlayView
        let nsHostingContentView = NSHostingView(rootView: CaptureOverlayView(onComplete: { imageData in
            if let imageData {
                print("Got image!")
            } else {
                print("User canceled")
            }
        }))
        self.contentView = nsHostingContentView

        // Additional window setup
        makeKeyAndOrderFront(self)

//        cHideCursor()
        setupGlobalEventHandlers()
    }

    private func setupGlobalEventHandlers() {
        // Setup for global event handlers
//        NSApp.activate(ignoringOtherApps: true)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if Int(event.keyCode) == kVK_Escape {
                print("escape")
                self?.cleanupAndClose()
                
                // To avoid the beep
                return nil
            } else {
                return nil
            }
        }

        // Local event monitor can also be added if needed
        // ...
    }

    private func cleanupAndClose() {
        cShowCursor()
        self.close()
    }
}



class OverlayWindow: NSWindow {
    // Will take callback onScreenshot: ImageData -> Void
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless.union(.fullSizeContentView), backing: backingStoreType, defer: flag)
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false // Change to true if you don't want to intercept events
        self.level = .screenSaver
        self.backgroundColor = .blue.withAlphaComponent(0.2)
        
        // We don't want to make it key to avoid any visible UI changes
        // from user's perspective the only thing that changed is the cursor glyph
        self.orderFrontRegardless()
        
        cHideCursor()
        
        // [try] TO catch escape
        NSApp.activate(ignoringOtherApps: true)
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
          if Int(event.keyCode) == kVK_Escape {
              print("escape")
              DispatchQueue.main.async {
//                  self?.cleanupAndClose()
              }
              
            return  // needed to get rid of purr sound
          } else {
            return
          }
        }
        
        // It would be nice if we can keep track of all control events outside the view and just use the view for drawing
//        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
//          if Int(event.keyCode) == kVK_Escape {
//              print("escape")
//              DispatchQueue.main.async {
////                  self?.cleanupAndClose()
//              }
//              
//            return event // needed to get rid of purr sound
//          } else {
//            return nil
//          }
//        }
        
        let nsHostingContentView = NSHostingView(rootView: CaptureOverlayView(onComplete: { imageData in
            if let imageData {
                print("Got image!")
            } else {
                print("User canceled")
            }
        }))
        self.contentView = nsHostingContentView
    }
    
    private func cleanupAndClose() {
        cShowCursor()
        // Remove window from screen
        // TODO: Pass the data back
        self.close()
    }
}
