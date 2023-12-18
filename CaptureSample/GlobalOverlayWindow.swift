//
//  GlobalOverlayWindow.swift
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/16/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import ApplicationServices

import Cocoa

// Seems veeery relevant! https://github.com/acheronfail/pixel-picker/blob/fae1ec38c938d625b5122aa5cbc497c9ef6effc1/README.md
// This seems like exactly what I need https://github.com/acheronfail/pixel-picker/blob/fae1ec38c938d625b5122aa5cbc497c9ef6effc1/Pixel%20Picker/ShowAndHideCursor.swift#L76

// Related, but too powerful it seems, requires accessibility
// https://developer.apple.com/documentation/coregraphics/1454426-cgeventtapcreate

// More examples online using NSCursor
// https://github.com/iina/iina/blob/79cd70c6197eeb0efd599c5c60e7c208292e3193/iina/InitialWindowController.swift#L512
// This one adds tracking + on cursor enter changes appearance
//
// https://github.com/viktorstrate/color-picker-plus/blob/940854dddd05a1fdb8d55ec36b464143cac2a280/Color%20Picker%20Plus/ScrollingTextField.swift#L36
//
// I can try running those projects and see what happens

// Works when cursor is above the newly created window
// And app needs to have focus - app should not capture focus

class CustomCursorView: NSView {
    override func resetCursorRects() {
        // Don't call super to avoid clearning existing cursor
        super.resetCursorRects()
        
        // Has to be in resetCursorRects
        // Calling this elsewhere is discarded
//        self.addCursorRect(self.bounds, cursor: .crosshair)
        
//        NSCursor.crosshair.push()
        
//        NSCursor.crosshair.push()
    }
    
    override func discardCursorRects() {
        super.discardCursorRects()
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        // TODO: If newWindow is nil - we are dismissing - cleanup
        
        
        
        if (newWindow == nil) {
            cShowCursor()
        } else {
            cHideCursor()
        }
        
        // Create a tracking area and add it to the view
//        let trackingArea = NSTrackingArea(rect: self.bounds, options: [.mouseMoved, .activeAlways], owner: self, userInfo: nil)
//        self.addTrackingArea(trackingArea)
        
//        self.window?.invalidateCursorRects(for: self)
    }

    // implement on enter / exit
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        print("mouse entered")

//       NSCursor.crosshair.push()
    }


    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        

        
        return
        
        // https://stackoverflow.com/a/3939241/5552584
//        let propertyString = CFStringCreateWithCString(kCFAllocatorDefault, "SetsCursorInBackground", 0)
//        CGSSetConnectionProperty(_CGSDefaultConnection(), _CGSDefaultConnection(), propertyString, kCFBooleanTrue)
//        
//        NSCursor.crosshair.push()
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
//        print("mouse down")
//        print(event.locationInWindow.x)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
//        print("mouse up")
        
        // Dismiss window - done with the screenshot
        NSCursor.crosshair.pop()
        self.window?.orderOut(nil)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
//        print("mouse moved")
    }
}

class OverlayWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless.union(.fullSizeContentView), backing: backingStoreType, defer: flag)
        self.backgroundColor = NSColor.blue.withAlphaComponent(0.2)
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false // Change to true if you don't want to intercept events
        self.level = .modalPanel
        
        self.contentView = CustomCursorView()
        
        // We don't want to make it key to avoid any visible UI changes
        // from user's perspective the only thing that changed is the cursor glyph
        self.orderFrontRegardless()
        
        // Without making key can't get the cursor to change
//        self.makeKeyAndOrderFront(nil)
    }

    
    override func makeKeyAndOrderFront(_ sender: Any?) {
//        NSCursor.crosshair.push()
        
        // https://developer.apple.com/documentation/appkit/nswindow/1419543-canbecomekeywindow
        // Won't become key I think?
        // -[NSWindow makeKeyWindow] called on CaptureSample.OverlayWindow 0x1222068f0 which returned NO from -[NSWindow canBecomeKeyWindow].
        // - there are conditions to become key window, without it seems the cursor stuff doesn't work
        super.makeKeyAndOrderFront(sender)
        
//        self.contentView?.resetCursorRects()
        
        // Note: Might be a better home is cursor setup override above
//        NSCursor.crosshair.push()
        
//        self.contentView?.discardCursorRects()
        
        
        
        // TODO: Handle escape?
        
        // Start listening for a left mouse down event
        // Once down event happens capture coordinates
        // Start tracking cursor position - on each position update - draw a
        // partially transparent rectangle between the anchor point and current cursor position
        
        // Since we are on window we can just track this with standard methods, right?
        // Maybe we can try local monitor?
//        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: {
//            event in
//            print("left mouse down")
//        })
//        
//        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged, handler: {
//            event in
//            print("left mouse dragging")
//        })
//        
//        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp, handler: {
//            event in
//            print("left mouse up")
//            
//            // TODO: Handle if no movement
////            NSCursor.crosshair.pop()
//        })
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {  // 53 is the key code for the Escape key
            self.orderOut(nil)   // Dismiss the window
        } else {
            super.keyDown(with: event)  // Handle other key presses
        }
    }
}
